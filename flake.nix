{
  description = "koyuch's NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-25.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      impermanence,
      home-manager,
      plasma-manager,
      nur,
      nix-vscode-extensions,
      ...
    }:
    {
      # Project scaffolding: `nix flake init -t ~/projects/think-nix#devshell`
      templates = {
        devshell = {
          path = ./templates/devshell;
          description = "flake devShell (nixos-unstable) + direnv + prek hooks (gitleaks)";
          welcomeText = ''
            # Dev shell scaffolded

            1. Edit `packages` in `flake.nix` and hooks in `.pre-commit-config.yaml`
            2. `git init` (if needed), then `git add -A && direnv allow`
               (installs the prek git hook on first load)
            3. Add CI that runs `nix develop -c prek run --all-files`
          '';
        };
        default = self.templates.devshell;
      };

      # Repo tooling: git hooks (.pre-commit-config.yaml via prek), formatter, linters.
      devShells.x86_64-linux.default =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.mkShell {
          packages = with pkgs; [
            prek
            gitleaks
            nixfmt
            deadnix
            statix
            shellcheck
            nil
          ];
          shellHook = ''
            [ -e .git/hooks/pre-commit ] || prek install >/dev/null
          '';
        };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;

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
          # `nix shell nixpkgs-unstable#<pkg>` resolves to the same unstable rev as pkgs-unstable
          { nix.registry.nixpkgs-unstable.flake = nixpkgs-unstable; }
          # Add home-manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
            home-manager.extraSpecialArgs = { inherit (specialArgs) pkgs-unstable; };
            home-manager.users.koyuch = import ./home.nix;
          }
        ];
      };
    };
}
