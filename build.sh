#!/usr/bin/env bash

set -e -u -o pipefail

OUTPUT_DIR=out
MAKE_VARIABLES=(
    ARCH=arm64
    SUBARCH=arm64
    CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
    CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32:-arm-none-eabi-}"
    O="$OUTPUT_DIR"
)

config() {
    local device="${1:?Usage: $0 config <device>}"
    local fragment="arch/arm64/configs/vendor/xiaomi/${device}.config"

    if [[ ! -f "${fragment}" ]]; then
        echo "Error: no config fragment for device '${device}' (${fragment})" >&2
        exit 1
    fi

    mkdir -p "${OUTPUT_DIR}"

    # Merge platform base + device fragment; device settings override on conflict.
    # -m: write merged config only, do not invoke make (we call olddefconfig next).
    ./scripts/kconfig/merge_config.sh -m -O "${OUTPUT_DIR}" \
        "arch/arm64/configs/vendor/xiaomi/mi845_defconfig" \
        "${fragment}" \
        "arch/arm64/configs/kernelsu.config" \
        "arch/arm64/configs/gcc-compat.config"

    # Fill in any symbols not covered by the fragments with their Kconfig defaults.
    make "${MAKE_VARIABLES[@]}" olddefconfig
}

xconfig() {
    make "${MAKE_VARIABLES[@]}" xconfig
}

menuconfig() {
    echo "menuconfig is not working" >&2
}

build() {
    make "${MAKE_VARIABLES[@]}" -j "$(nproc)"
}

clean() {
    make "${MAKE_VARIABLES[@]}" clean
}

distclean() {
    make "${MAKE_VARIABLES[@]}" distclean
}

cmd="${1:?Usage: $0 <command> [args...]}"
shift
"$cmd" "$@"
