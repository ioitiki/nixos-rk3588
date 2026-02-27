# NixOS on Orange Pi 5 — NVMe Install

NixOS configuration for Orange Pi 5 installed directly to NVMe SSD.

## Prerequisites

- Orange Pi 5 booted into Armbian (or another working Linux) from SD/eMMC
- NVMe SSD installed and visible as `/dev/nvme0n1`
- U-Boot already flashed to SPI (the board's SPI flash must have u-boot to boot from NVMe)

## Partition and format the NVMe

```bash
fdisk /dev/nvme0n1
# Create GPT table, p1 = 512MB type EFI, p2 = remainder type Linux

mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p2

mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

## Install

```bash
git clone https://github.com/ioitiki/nixos-rk3588.git
cd nixos-rk3588/examples/nvme-opi5
nixos-install --flake .#orangepi5 --root /mnt
```

## After install

Set your password on first boot:

```bash
passwd andy
```
