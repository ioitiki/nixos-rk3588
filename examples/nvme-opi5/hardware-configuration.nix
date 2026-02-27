{lib, pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = {
      zfs = lib.mkForce false;
    };

    kernelParams = lib.mkBefore [
      "rootwait"
      "earlycon"
      "consoleblank=0"
      "console=ttyS2,1500000"
      "console=tty1"
    ];

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
