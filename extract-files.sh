#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=poplar
VENDOR=lenovo

# Determine script directories
MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_ROOT="$(cd "${MY_DIR}/../../.." 2>/dev/null && pwd || echo "")"
HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"

CLEAN_VENDOR=true
KANG=
SECTION=
SRC=

# Normalize paths when executing under Windows / MSYS / Git Bash / WSL
normalize_path() {
    local P="$1"
    if [ -z "$P" ] || [ "$P" = "adb" ]; then
        echo "$P"
        return
    fi
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -u "$P"
    elif [[ "$P" =~ ^[A-Za-z]:[\\/] ]]; then
        local DRIVE="${P:0:1}"
        DRIVE="$(echo "$DRIVE" | tr '[:upper:]' '[:lower:]')"
        local REST="${P:2}"
        REST="${REST//\\//}"
        if [ -d "/mnt/${DRIVE}" ]; then
            echo "/mnt/${DRIVE}${REST}"
        else
            echo "/${DRIVE}${REST}"
        fi
    else
        echo "$P"
    fi
}

# Parse command line options
while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        -s | --source)
            SRC="${2}"
            shift
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
else
    SRC="$(normalize_path "${SRC}")"
fi

# Mode A: LineageOS extract_utils is available
if [ -n "${ANDROID_ROOT}" ] && [ -f "${HELPER}" ]; then
    export TARGET_DISABLE_XML_FIXING=true
    source "${HELPER}"

    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" ${KANG} ${SECTION:+--section "${SECTION}"}

    "${MY_DIR}/setup-makefiles.sh"
    exit 0
fi

# Mode B: Standalone Fallback Extraction Engine
echo "Notice: Standard extract_utils.sh not found at ${HELPER}."
echo "Activating standalone fallback extraction engine for ${VENDOR}/${DEVICE}..."

PROPRIETARY_DIR="${MY_DIR}/proprietary"
PROPLIST="${MY_DIR}/proprietary-files.txt"

if [ ! -f "${PROPLIST}" ]; then
    echo "Error: Proprietary files list not found at ${PROPLIST}!"
    exit 1
fi

if [ "${CLEAN_VENDOR}" = true ]; then
    echo "Cleaning existing proprietary directory: ${PROPRIETARY_DIR}"
    rm -rf "${PROPRIETARY_DIR}"
fi
mkdir -p "${PROPRIETARY_DIR}"

TOTAL=0
SUCCESS=0
MISSING=0
IN_SECTION=true

if [ -n "${SECTION}" ]; then
    IN_SECTION=false
    echo "Extracting only section: ${SECTION}"
fi

echo "Extracting proprietary files from source: ${SRC}"

while IFS= read -r line || [ -n "$line" ]; do
    # Trim leading and trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    # Handle section headers
    if [[ "$line" =~ ^# ]]; then
        if [ -n "${SECTION}" ]; then
            SEC_HEADER="${line###}"
            SEC_HEADER="${SEC_HEADER#"${SEC_HEADER%%[![:space:]]*}"}"
            SEC_HEADER_LOWER="$(echo "$SEC_HEADER" | tr '[:upper:]' '[:lower:]')"
            TARGET_SEC_LOWER="$(echo "$SECTION" | tr '[:upper:]' '[:lower:]')"
            if [[ "$SEC_HEADER_LOWER" == *"$TARGET_SEC_LOWER"* ]]; then
                IN_SECTION=true
            else
                IN_SECTION=false
            fi
        fi
        continue
    fi

    [ -z "$line" ] && continue
    [ "$IN_SECTION" = false ] && continue

    # Parse pinned hash
    PINNED_HASH=""
    if [[ "$line" =~ \| ]]; then
        PINNED_HASH="$(echo "$line" | cut -d'|' -f2 | tr '[:upper:]' '[:lower:]')"
        line="${line%%|*}"
    fi

    # Strip package dash
    line="${line#-}"

    # Strip semicolon flags
    line="${line%%;*}"

    # Separate src:dst
    if [[ "$line" =~ : ]]; then
        SRC_FILE="${line%%:*}"
        DST_FILE="${line##*:}"
    else
        SRC_FILE="$line"
        DST_FILE="$line"
    fi

    TOTAL=$((TOTAL + 1))
    TARGET_PATH="${PROPRIETARY_DIR}/${DST_FILE}"
    TARGET_SUBDIR="$(dirname "${TARGET_PATH}")"
    mkdir -p "${TARGET_SUBDIR}"

    COPIED=false

    if [ "${SRC}" = "adb" ]; then
        for CANDIDATE in "/${SRC_FILE}" "/system/${SRC_FILE}" "/vendor/${SRC_FILE#vendor/}"; do
            if adb pull "${CANDIDATE}" "${TARGET_PATH}" >/dev/null 2>&1; then
                COPIED=true
                break
            fi
        done
    else
        REL_VENDOR="${SRC_FILE#vendor/}"
        REL_DLKM="${SRC_FILE#vendor_dlkm/}"
        for CANDIDATE in \
            "${SRC}/${SRC_FILE}" \
            "${SRC}/${SRC_FILE#/}" \
            "${SRC}/vendor/${REL_VENDOR}" \
            "${SRC}/vendor_dlkm/${REL_DLKM}" \
            "${SRC}/system/${SRC_FILE}" \
            "${SRC}/system/vendor/${REL_VENDOR}" \
            "${SRC}/image/${SRC_FILE}" \
            "${SRC}/image/vendor/${REL_VENDOR}" \
            "${SRC}/${REL_VENDOR}" \
            "${SRC}/${REL_DLKM}"; do
            if [ -f "${CANDIDATE}" ]; then
                cp -f "${CANDIDATE}" "${TARGET_PATH}"
                COPIED=true
                break
            fi
        done
    fi

    if [ "${COPIED}" = true ]; then
        SUCCESS=$((SUCCESS + 1))
        if [ -n "${PINNED_HASH}" ] && [ -z "${KANG}" ]; then
            ACTUAL_HASH="$(sha1sum "${TARGET_PATH}" 2>/dev/null | awk '{print $1}')"
            if [ -n "${ACTUAL_HASH}" ] && [ "${ACTUAL_HASH}" != "${PINNED_HASH}" ]; then
                echo "Warning: Hash mismatch on ${DST_FILE} (expected ${PINNED_HASH}, got ${ACTUAL_HASH})"
            fi
        fi
    else
        MISSING=$((MISSING + 1))
        echo "  [MISSING] ${SRC_FILE}"
    fi

done <"${PROPLIST}"

echo "Extraction complete: ${SUCCESS}/${TOTAL} extracted, ${MISSING} missing."

# Invoke setup-makefiles.sh to generate makefiles
"${MY_DIR}/setup-makefiles.sh"
