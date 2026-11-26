# Proprietary vendor tree for Lenovo Tab TB311FU (`poplar`)

This repository provides proprietary Lenovo binaries and firmware used by the `device/lenovo/poplar` device tree for LineageOS 21.0. It is intended for the Lenovo Tab Wi-Fi, model `TB311FU` (`poplar` / `poplar_row_wifi`), on the MediaTek MT8786 / MT6768 platform.

## Contents

The tree contains extracted vendor libraries, firmware, kernel modules for vendor_dlkm, audio tuning data, and generated Android makefiles. `proprietary-files.txt` is the source inventory; the proprietary payloads live under `proprietary/`. Device-specific configuration that belongs to the device tree is maintained separately.

Blobs are based on the Lenovo stock firmware build `TB311FU_ROW_OPEN_USER_M1457.5_W_ZUI_17.5.36.508_ST_261024`. Do not assume blobs from another model, region, or firmware build are interchangeable.

## Integration

Place this repository at `vendor/lenovo/poplar` and use it with compatible device and kernel trees:

```bash
git clone -b lineage-21.0 https://github.com/BangerSoul/proprietary_vendor_lenovo_poplar.git vendor/lenovo/poplar
```

The device tree inherits `poplar-vendor.mk` and includes `BoardConfigVendor.mk`. Keep this vendor branch synchronized with the matching `lineage-21.0` device/kernel inputs. The device uses Android boot header v4 and carries recovery in `vendor_boot`; this vendor tree supplies blobs, not a standalone recovery image or recovery partition configuration.

## Extracting and regenerating

Use a compatible LineageOS `tools/extract-utils` checkout. Point extraction at a legally obtained, unpacked stock firmware dump, then regenerate the build files:

```bash
./extract-files.sh /path/to/unpacked_stock_dump
./setup-makefiles.sh
```

Review changes to `proprietary-files.txt` and generated makefiles before committing. Do not publish or redistribute proprietary binaries unless you have the required rights.

## Recovery development

TWRP and OrangeFox build helpers are maintained in the device repository's [`recovery/twrp-orangefox` branch](https://github.com/BangerSoul/android_device_lenovo_poplar/tree/recovery/twrp-orangefox). Use vendor files only with a compatible recovery/Android base. Recovery builders target `vendorbootimage`; actual display, touch, partition, and decryption support must be validated on the device.

## Licensing

Build scripts, makefiles, and definitions are covered by their stated SPDX license headers. Proprietary firmware, binaries, and related Lenovo assets remain the property of their respective copyright holders and are not relicensed by this repository.

## Repository

- Device tree: [BangerSoul/android_device_lenovo_poplar](https://github.com/BangerSoul/android_device_lenovo_poplar)
- Branch: `lineage-21.0`
