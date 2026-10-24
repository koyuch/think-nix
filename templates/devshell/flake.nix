{
  description = "Project dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # Runtime/toolchain: pin majors to the deploy target, e.g.
            # nodejs_24 pnpm | python313 uv | jdk21 | go | rustc cargo
            just

            # Git hooks (.pre-commit-config.yaml) + their tools
            prek
            gitleaks
            nixfmt
          ];

          shellHook = ''
            # install the git hook shim once per clone (no-op outside a git repo)
            if [ -d .git ] && [ ! -e .git/hooks/pre-commit ]; then prek install >/dev/null; fi
          '';
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
