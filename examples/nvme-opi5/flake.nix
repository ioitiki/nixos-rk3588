{
  description = "NixOS on Orange Pi 5 NVMe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-rk3588.url = "github:ioitiki/nixos-rk3588";
  };

  outputs = { nixpkgs, nixos-rk3588, ... }: {
    nixosConfigurations.orangepi5 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        nixos-rk3588.nixosModules.boards.orangepi5.core
        ./hardware-configuration.nix
        ./configuration.nix
      ];
    };
  };
}
