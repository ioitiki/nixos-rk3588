{lib, pkgs, ...}: {
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
  ];

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
    extraGroups = ["users" "wheel"];
  };

  system.stateVersion = "26.05";
}
