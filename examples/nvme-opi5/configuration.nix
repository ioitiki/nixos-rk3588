{lib, pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    neofetch
    lm_sensors
    btop
    mtdutils
    i2c-tools
    minicom
    firefox
    xfce.xfce4-terminal
  ];

  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PasswordAuthentication = true;
    };
    openFirewall = true;
  };

  users.users.andy = {
    initialPassword = "changeme";
    isNormalUser = true;
    home = "/home/andy";
    extraGroups = ["users" "wheel" "video" "audio" "input"];
  };

  system.stateVersion = "26.05";
}
