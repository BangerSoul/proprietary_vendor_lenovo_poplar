# Proprietary Vendor Tree for Lenovo Tab M9 / Tab M11 (`poplar` / `TB311FU`)

This repository contains the prebuilt proprietary vendor binaries, firmware, kernel modules (`vendor_dlkm`), audio tuning parameters, and build makefiles for the **Lenovo TB311FU** (`poplar`), extracted directly from official factory firmware.

---

## Proprietary Blob Inventory

- **Total Staged Blobs**: **473** proprietary files declared in `proprietary-files.txt` and staged under `proprietary/`.
- **Extraction Source**: Official Lenovo RSA Stock ROM `TB311FU_ROW_OPEN_USER_M1457.5_W_ZUI_17.5.36.508_ST_261024` (`super.img` -> EROFS `vendor` and `vendor_dlkm` logical partitions).

### Subsystem Breakdown

| Subsystem | Key Assets & HALs |
|---|---|
| **Graphics & Display** | ARM Mali-G52 EGL/Vulkan (`libGLES_mali.so`, `vulkan.mali.so`), MT6768 Hardware Composer (`hwcomposer.mt6768.so`, `android.hardware.graphics.composer@3.3-service`), Gralloc / Allocator V2 / Mapper, PQ AIDL |
| **Audio HAL & Smart PA** | `audio.primary.mt6768.so`, `android.hardware.audio.service-aidl.mediatek`, Awinic Smart PA (`aw883xx_acf.bin`, `snd-soc-aw883xx.ko`), Aurisys DSP (`audio_param/` & `audio_param_1/` XML profiles), `snd-soc-mt6768-afe.ko`, `snd-soc-mt6358.ko` |
| **Camera & ISP 4.0T** | `camerahalserver`, `android.hardware.camera.provider@2.6-impl-mediatek.so`, 3A CCU firmware (`lib3a.ccu`), `camera_isp_4_t.ko`, `imgsensor_isp4_t.ko`, `libcamalgo.*.so` |
| **Connectivity (Wi-Fi / BT / GNSS)** | Out-of-tree Wi-Fi module `wlan_drv_gen4m_6768.ko`, Wi-Fi/BT firmware (`WIFI_RAM_CODE_soc1_0_1a_1.bin`, `soc1_0_ram_*_hdr.bin`), `bt_drv_connac1x.ko`, `android.hardware.bluetooth-service-mediatek`, `gps_drv_stp.ko`, `mnld` |
| **Sensors, Touch & DRM/TEE** | `sensors.mt6768.so`, `sensorHub.ko`, Himax/Jadard/Novatek touch firmware & modules (`hx83102e.ko`, `jd9366ts.ko`, `nt36523h.ko`), Microtrust TEE (`teei_daemon`, `.ta` trustlets), Google Widevine (`com.google.android.widevine.nonupdatable.apex`, `widevine_driver.ko`) |
| **Thermal, Power & Charging** | `android.hardware.thermal-service.mediatek`, `vendor.mediatek.hardware.mtkpower-service.mediatek`, `CPU_DVFS.ko`, `MTK_INTERNAL_SPM.ko`, `Upower.ko`, `vendor.lenovo.hardware.battery-service`, `fuelgauged` |

---

## Build Makefile Integration

The vendor tree integrates directly with `device/lenovo/poplar`:

- **`poplar-vendor.mk`**: Inherited by `device/lenovo/poplar/device.mk` via `$(call inherit-product, vendor/lenovo/poplar/poplar-vendor.mk)`. Configures `PRODUCT_COPY_FILES` (firmware, Aurisys XMLs, `.ko` modules to `$(TARGET_COPY_OUT_VENDOR_DLKM)`) and `PRODUCT_PACKAGES` (HAL binaries/libraries).
- **`BoardConfigVendor.mk`**: Included by `device/lenovo/poplar/BoardConfig.mk`, sets `BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs` and `BOARD_VENDOR_SEPOLICY_DIRS += vendor/lenovo/poplar/sepolicy/vendor`.
- **`Android.mk` & `Android.bp`**: Declares the `vendor/lenovo/poplar` Soong namespace and prebuilt module guard for `TARGET_DEVICE == poplar`.

---

## Re-Extracting Blobs & Regenerating Makefiles

Both `extract-files.sh` and `setup-makefiles.sh` support standard LineageOS `tools/extract-utils` as well as standalone execution:

```bash
# Extract proprietary blobs from an unpacked stock ROM dump directory
./extract-files.sh /path/to/unpacked_stock_dump

# Regenerate poplar-vendor.mk, BoardConfigVendor.mk, Android.mk, Android.bp
./setup-makefiles.sh
```

*(Note: Prebuilt binaries with vendor-private SONAMEs or symbols preserve `;DISABLE_CHECKELF` in `proprietary-files.txt` to ensure clean Soong ELF checks.)*

---

## Copyright & License

- **Build Makefiles, Scripts & Definitions**: Licensed under the **Apache License, Version 2.0** (`SPDX-License-Identifier: Apache-2.0`), Copyright (C) 2024-2026 The LineageOS Project.
- **Proprietary Blobs (`proprietary/`)**: All binary firmware, shared libraries, kernel modules, and vendor configurations remain the copyrighted intellectual property of **Lenovo Group Ltd.**, **MediaTek Inc.**, **ARM Ltd.**, **Awinic Technology**, **Microtrust**, and **Google LLC**, extracted from stock factory firmware solely for device compatibility and personal LineageOS builds.

---

## Repository & GitHub Publishing

- **Remote (`origin`)**: `https://github.com/iamsh/proprietary_vendor_lenovo_poplar.git`
- **Target Branch**: `lineage-21.0`

```bash
git remote -v
git push -u origin lineage-21.0
```
