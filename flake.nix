{
  description = "koyuch's NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self
    , nixpkgs
    , nixpkgs-unstable
    , impermanence
    , home-manager
    , plasma-manager
    , nur
    , nix-vscode-extensions
    , ... }@inputs: {
    # hostname
    nixosConfigurations.think-nix = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      # The `specialArgs` parameter passes the non-default nixpkgs instances to other nix modules
      specialArgs = {
        # To use packages from nixpkgs-unstable, we configure some parameters for it first
        pkgs-unstable = import nixpkgs-unstable {
          # Refer to the `system` parameter from the outer scope recursively
          inherit system;
          config.allowUnfree = true;
          overlays = [
            nix-vscode-extensions.overlays.default
          ];
        };
      };
      modules = [
        impermanence.nixosModules.impermanence
        # Adds the NUR overlay
        nur.modules.nixos.default
        # Import the previous configuration.nix we used, so the old configuration file still takes effect
        ./configuration.nix

        # Add home-manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];
          home-manager.extraSpecialArgs = { inherit (specialArgs) pkgs-unstable; };
          home-manager.users.koyuch = import ./home.nix;
        }
      ];
    };
  };
}