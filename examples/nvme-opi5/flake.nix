{
  description = "NixOS on Orange Pi 5 NVMe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-rk3588.url = "github:ioitiki/nixos-rk3588";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-rk3588, home-manager, ... }:
    let
      system = "aarch64-linux";
      pkgsNative = import nixpkgs { inherit system; };
    in {
    nixosConfigurations.orangepi5 = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs.rk3588 = {
        inherit nixpkgs;
        pkgsKernel = pkgsNative;
      };
      modules = [
        nixos-rk3588.nixosModules.boards.orangepi5.core
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.andy = import ./home.nix;
        }
      ];
    };
  };
}
