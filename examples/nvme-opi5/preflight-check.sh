#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass=0
fail=0
warn=0

ok()   { echo -e "  ${GREEN}[PASS]${NC} $1"; ((pass++)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((fail++)); }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; ((warn++)); }

echo "============================================"
echo "  Orange Pi 5 NVMe NixOS Pre-flight Check"
echo "============================================"
echo

# --- 1. SPI / U-Boot ---
echo "1. SPI NOR Flash (U-Boot)"
if [ -e /dev/mtdblock0 ]; then
    size=$(cat /proc/mtd 2>/dev/null | grep mtd0 | awk '{print $2}')
    if [ -n "$size" ]; then
        ok "/dev/mtdblock0 exists, size 0x${size}"
    else
        ok "/dev/mtdblock0 exists"
    fi
    # check if SPI has actual data (not all 0xff = erased)
    if command -v hexdump &>/dev/null; then
        sample=$(dd if=/dev/mtdblock0 bs=512 count=1 2>/dev/null | hexdump -C | head -5)
        if echo "$sample" | grep -q "ff ff ff ff ff ff ff ff  ff ff ff ff ff ff ff ff"; then
            fail "SPI flash appears erased — U-Boot likely not flashed"
            echo "       Run: sudo armbian-install → pick 'MTD Flash'"
        else
            ok "SPI flash contains data (U-Boot appears flashed)"
        fi
    else
        warn "hexdump not available, cannot verify SPI contents"
    fi
else
    fail "/dev/mtdblock0 not found — SPI flash not detected"
fi
echo

# --- 2. NVMe device ---
echo "2. NVMe Device"
if [ -b /dev/nvme0n1 ]; then
    ok "/dev/nvme0n1 exists"
else
    fail "/dev/nvme0n1 not found"
fi

if [ -b /dev/nvme0n1p1 ]; then
    ok "Boot partition /dev/nvme0n1p1 exists"
else
    fail "Boot partition /dev/nvme0n1p1 not found"
fi

if [ -b /dev/nvme0n1p2 ]; then
    ok "Root partition /dev/nvme0n1p2 exists"
else
    fail "Root partition /dev/nvme0n1p2 not found"
fi
echo

# --- 3. Mount check ---
echo "3. NVMe Mounts"
root_mounted=false
boot_mounted=false
root_mp=""
boot_mp=""

if mount | grep -q '/dev/nvme0n1p2'; then
    root_mp=$(mount | grep '/dev/nvme0n1p2' | awk '{print $3}')
    ok "Root partition mounted at ${root_mp}"
    root_mounted=true
else
    fail "Root partition /dev/nvme0n1p2 not mounted"
    echo "       Run: mount /dev/nvme0n1p2 /mnt"
fi

if mount | grep -q '/dev/nvme0n1p1'; then
    boot_mp=$(mount | grep '/dev/nvme0n1p1' | awk '{print $3}')
    ok "Boot partition mounted at ${boot_mp}"
    boot_mounted=true
else
    fail "Boot partition /dev/nvme0n1p1 not mounted"
    echo "       Run: mkdir -p /mnt/boot && mount /dev/nvme0n1p1 /mnt/boot"
fi
echo

# --- 4. extlinux.conf ---
echo "4. Boot Configuration (extlinux)"
if $boot_mounted; then
    extlinux=""
    for path in "${boot_mp}/extlinux/extlinux.conf" "${boot_mp}/nixos/extlinux/extlinux.conf"; do
        if [ -f "$path" ]; then
            extlinux="$path"
            break
        fi
    done

    if [ -n "$extlinux" ]; then
        ok "Found ${extlinux}"
        echo
        echo "    --- extlinux.conf contents ---"
        sed 's/^/    /' "$extlinux"
        echo "    --- end ---"
        echo

        # check kernel path exists
        kernel_path=$(grep -i '^\s*kernel\|^\s*linux' "$extlinux" 2>/dev/null | head -1 | awk '{print $2}')
        if [ -n "$kernel_path" ]; then
            # kernel path is relative to boot partition or absolute
            if [ -f "${boot_mp}/${kernel_path}" ] || [ -f "${kernel_path}" ]; then
                ok "Kernel image referenced in extlinux.conf exists"
            else
                # might be relative to root
                if $root_mounted && [ -f "${root_mp}${kernel_path}" ]; then
                    ok "Kernel image found at ${root_mp}${kernel_path}"
                else
                    warn "Cannot verify kernel path: ${kernel_path}"
                fi
            fi
        fi
    else
        fail "No extlinux.conf found under ${boot_mp}"
    fi
elif $root_mounted; then
    # boot might be inside root
    for path in "${root_mp}/boot/extlinux/extlinux.conf" "${root_mp}/boot/nixos/extlinux/extlinux.conf"; do
        if [ -f "$path" ]; then
            ok "Found ${path}"
            echo
            echo "    --- extlinux.conf contents ---"
            sed 's/^/    /' "$path"
            echo "    --- end ---"
            break
        fi
    done
fi
echo

# --- 5. Nix store ---
echo "5. NixOS Installation"
if $root_mounted; then
    nix_store="${root_mp}/nix/store"
    if [ -d "$nix_store" ]; then
        count=$(ls "$nix_store" 2>/dev/null | wc -l)
        ok "/nix/store exists with ${count} paths"
    else
        fail "/nix/store not found on root partition"
    fi

    if [ -d "${root_mp}/etc" ]; then
        ok "/etc directory exists"
    else
        fail "/etc not found on root partition"
    fi
else
    warn "Root not mounted, skipping NixOS install check"
fi
echo

# --- 6. Filesystem types ---
echo "6. Filesystem Types"
if command -v blkid &>/dev/null; then
    p1_type=$(blkid -s TYPE -o value /dev/nvme0n1p1 2>/dev/null || true)
    p2_type=$(blkid -s TYPE -o value /dev/nvme0n1p2 2>/dev/null || true)

    if [ "$p1_type" = "vfat" ]; then
        ok "/dev/nvme0n1p1 is vfat (expected)"
    elif [ -n "$p1_type" ]; then
        fail "/dev/nvme0n1p1 is ${p1_type} (expected vfat)"
    fi

    if [ "$p2_type" = "ext4" ]; then
        ok "/dev/nvme0n1p2 is ext4 (expected)"
    elif [ -n "$p2_type" ]; then
        fail "/dev/nvme0n1p2 is ${p2_type} (expected ext4)"
    fi
else
    warn "blkid not available, skipping filesystem check"
fi
echo

# --- Summary ---
echo "============================================"
echo -e "  Results: ${GREEN}${pass} passed${NC}, ${RED}${fail} failed${NC}, ${YELLOW}${warn} warnings${NC}"
echo "============================================"
echo
if [ "$fail" -eq 0 ]; then
    echo -e "${GREEN}All checks passed. You should be safe to remove the Armbian drive and reboot.${NC}"
else
    echo -e "${RED}Some checks failed. Review the output above before rebooting.${NC}"
fi
