{lib, pkgs, ...}: {
  boot = {
    # kernelPackages is set by orangepi5.core via the vendor kernel
    supportedFilesystems = {
      zfs = lib.mkForce false;
    };

    loader = {
      grub.enable = lib.mkForce false;
      generic-extlinux-compatible.enable = lib.mkForce true;
    };
  };

  fileSystems."/" = {
    device = "/dev/nvme0n1p2";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
  };
}
