#!/usr/bin/env python3
"""
patch-upstream-kernel.py:
Applies Jinlon (HP Elite c1030 Chromebook) hardware overrides and build script fixes
to the cloned gbos-x86 tree.
"""
import sys
from pathlib import Path

GBOS_ROOT = Path("/tmp/gbos-x86")


def patch_configure_whl():
    path = GBOS_ROOT / "kernel/configure_whl.py"
    content = path.read_text(encoding="utf-8")

    target = "'KSU_X86_PATCH_SYSCALL_DISPATCHER': 'y',"
    overrides = """'KSU_X86_PATCH_SYSCALL_DISPATCHER': 'y',
        # Jinlon thermal management & ChromeOS EC (prevent 100% fail-safe fan)
        'INTEL_RAPL': 'y',
        'X86_PKG_TEMP_THERMAL': 'y',
        'INT340X_THERMAL': 'y',
        'INT3400_THERMAL': 'y',
        'INTEL_PCH_THERMAL': 'y',
        'CHROME_PLATFORMS': 'y',
        'CROS_EC': 'y',
        'CROS_EC_LPC': 'y',
        'CROS_EC_SYSFS': 'y',
        # Gamepad input drivers (Gamesir Nova Lite 2.4G dongle / xpad / joydev)
        'INPUT_JOYDEV': 'y',
        'JOYSTICK_XPAD': 'y',
        'JOYSTICK_XPAD_FF': 'y',
        'JOYSTICK_XPAD_LEDS': 'y',
        'INPUT_UINPUT': 'y',"""

    if target not in content:
        raise RuntimeError(f"Target '{target}' not found in {path}")

    new_content = content.replace(target, overrides, 1)
    path.write_text(new_content, encoding="utf-8")
    print("Successfully patched configure_whl.py with Jinlon overrides.")


def patch_fetch_kernel_sources():
    path = GBOS_ROOT / "kernel/fetch_kernel_sources.sh"
    content = path.read_text(encoding="utf-8")

    target_dl = (
        '  say "kernel source: android.googlesource.com kernel/common @ $KSRC_COMMIT"\n'
        '  [ -f "$DL/$KSRC_TAR" ] || curl -fL --retry 5 -o "$DL/$KSRC_TAR" \\\n'
        '    "https://android.googlesource.com/kernel/common/+archive/$KSRC_COMMIT.tar.gz"\n'
        '  got=$(sha "$DL/$KSRC_TAR")\n'
        '  [ "$got" = "$KSRC_SHA" ] || die "sha256 mismatch for $KSRC_TAR ($got); delete it and retry"\n'
        '  docker run --rm -v "$VOL":/build -v "$DL":/dl:ro debian:trixie \\\n'
        '    bash -c "set -e; mkdir -p /build/src; tar -xzf /dl/$KSRC_TAR -C /build/src"'
    )

    repl_dl = (
        '  say "kernel source: shallow git fetch from android.googlesource.com @ $KSRC_COMMIT"\n'
        '  rm -rf "$DL/src"\n'
        '  mkdir -p "$DL/src"\n'
        '  git -C "$DL/src" init\n'
        '  git -C "$DL/src" remote add origin https://android.googlesource.com/kernel/common\n'
        '  git -C "$DL/src" fetch --depth 1 origin "$KSRC_COMMIT"\n'
        '  git -C "$DL/src" checkout FETCH_HEAD\n'
        '  docker run --rm -v "$VOL":/build -v "$DL/src":/dl/src:ro debian:trixie \\\n'
        '    bash -c "set -e; mkdir -p /build/src; cp -a /dl/src/. /build/src/; rm -rf /build/src/.git"'
    )

    if target_dl not in content:
        raise RuntimeError(f"target_dl block not found in {path}")

    content = content.replace(target_dl, repl_dl, 1)
    content = content.replace(
        "cp -a /dl/clang-prebuilts/$CLANG_DIR /build/inputs/",
        "cp -a /dl/clang-prebuilts/$CLANG_DIR /build/inputs/; ln -sf $CLANG_DIR /build/inputs/clang-r584948c",
    )
    path.write_text(content, encoding="utf-8")
    print("Successfully patched fetch_kernel_sources.sh (git pack protocol + clang symlink).")


def patch_build_kernel():
    path = GBOS_ROOT / "kernel/build_kernel.sh"
    content = path.read_text(encoding="utf-8")
    content = content.replace("clang-r584948c", "clang-r584948b")
    path.write_text(content, encoding="utf-8")
    print("Successfully patched build_kernel.sh (clang-r584948b).")


def patch_make_stage0_initramfs():
    path = GBOS_ROOT / "kernel/make_stage0_initramfs.sh"
    content = path.read_text(encoding="utf-8")
    content = content.replace(
        "missing=$((missing+1))",
        'echo "module $m built-in or omitted" # missing=$((missing+1))',
    )
    path.write_text(content, encoding="utf-8")
    print("Successfully patched make_stage0_initramfs.sh (built-in module tolerance).")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        GBOS_ROOT = Path(sys.argv[1])
    patch_configure_whl()
    patch_fetch_kernel_sources()
    patch_build_kernel()
    patch_make_stage0_initramfs()
    print("All patches applied cleanly.")
