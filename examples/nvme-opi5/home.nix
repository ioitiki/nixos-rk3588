{pkgs, ...}: {
  home.username = "andy";
  home.homeDirectory = "/home/andy";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    zed-editor
  ];

  programs.home-manager.enable = true;
}
