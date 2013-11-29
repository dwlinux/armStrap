if [ -z "${BUILD_BOOTLOADER_TYPE}" ]; then
  BUILD_BOOTLOADER_TYPE="u-boot-sunxi"
fi

if [ -z "${BUILD_BOOTLOADER_FAMILLY}" ]; then
  BUILD_BOOTLOADER_FAMILLY="cubieboard"
fi

if [ -z "${BUILD_BOOTLOADER_FEX}" ]; then
  BUILD_BOOTLOADER_FEX="${BUILD_BOOTLOADER_FAMILLY}.fex"
fi

if [ -z "${BUILD_BOOTLOADER_FEXSRC}" ]; then
  BUILD_BOOTLOADER_FEXSRC="${ARMSTRAP_SRC}/sunxi-boards"
fi

if [ -z "${BUILD_BOOTLOADER_FEXGIT}" ]; then
  BUILD_BOOTLOADER_FEXGIT="https://github.com/linux-sunxi/sunxi-boards.git"
fi

if [ -z "${BUILD_BOOTLOADER_FEXBRN}" ]; then
  BUILD_BOOTLOADER_FEXBRN=""
fi

if [ -z "${BUILD_BOOTLOADER_ARCH}" ]; then 
  BUILD_BOOTLOADER_ARCH="arm"
fi

if [ -z "${BUILD_BOOTLOADER_CPU}" ]; then 
  BUILD_BOOTLOADER_CPU="a10"
fi

if [ -z "${BUILD_BOOTLOADER_EABI}" ]; then 
  BUILD_BOOTLOADER_EABI="hf"
fi

if [ -z "${BUILD_BOOTLOADER_SOURCE}" ]; then
  BUILD_BOOTLOADER_SOURCE="${ARMSTRAP_SRC}/${BUILD_BOOTLOADER_TYPE}"
fi

if [ -z "${BUILD_BOOTLOADER_CFLAGS}" ]; then
  BUILD_BOOTLOADER_CFLAGS=""
fi

if [ -z "${BUILD_BOOTLOADER_GITSRC}" ]; then
  BUILD_BOOTLOADER_GITSRC="https://github.com/linux-sunxi/u-boot-sunxi.git"
fi

if [ -z "${BUILD_BOOTLOADER_GITBRN}" ]; then
  BUILD_BOOTLOADER_GITBRN="sunxi"
fi

if [ -z "${BUILD_BOORLOADER_COMPRESS}" ]; then
  BUILD_BOORLOADER_COMPRESS="tar -cJvf"
fi
