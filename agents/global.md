# Global agent instructions (koyuch @ think-nix)

User-wide rules for every AI agent on this machine (Kilo, opencode, Gemini/Antigravity, Claude, pi, aider).
Project `AGENTS.md` files add to these rules, and their rules win when the two conflict.
Source of truth: `~/projects/think-nix/agents/global.md`. Home Manager symlinks it into each tool's config dir,
so edit that file, never the symlinks.

## This machine

- **NixOS 26.05, flake-based.** System + Home Manager config lives in `~/projects/think-nix`
  (`/etc/nixos/*` are symlinks to it). User: `koyuch`, shell: zsh (oh-my-zsh + p10k), desktop: KDE Plasma 6 (Wayland).
- **Impermanence:** the root subvolume is wiped on every boot. Only `/home`, `/nix`, `/persist` and
  `/var/lib/libvirt` survive. Anything written by hand to `/etc`, `/var`, `/root`, `/usr/local`, `/opt`
  is lost on reboot, so never install or configure things there imperatively.
- **No FHS.** There is no `/usr/bin/<tool>` (except `/usr/bin/env`) and no `/lib`. Use `#!/usr/bin/env bash` shebangs.
  Prebuilt binaries usually still run thanks to `nix-ld`, but a nixpkgs package is always the better choice.
- **Home Manager owns many dotfiles** (`~/.zshrc`, `~/.config/git`, `~/.ssh/config`, `~/.gnupg/*`, this file…).
  They are read-only symlinks into `/nix/store`. Change them in `home.nix`, not in place.
- **Containers:** rootless Podman with Docker compatibility (`docker` CLI alias, `DOCKER_HOST` points at the Podman socket),
  plus `podman-compose`. VMs: libvirt / virt-manager. Network: Tailscale (`*.tail5de296.ts.net`).
- **Secrets:** `pass` (GPG); gpg-agent is also the SSH agent. Git commits are **GPG-signed by default**:
  never disable signing. A commit may wait on a pinentry prompt. Never read `~/.password-store`, print tokens, or
  write secrets into repos.
- Projects live in `~/projects/<name>`.

## Getting tools: declarative-first ladder

Before using a tool, check whether it's already available: `command -v <tool>`. The base set already on PATH includes
`rg fd fzf bat eza jq yq gh just git curl xh httpie uv node python3 jdk kubectl helm k9s awscli2 ansible mise direnv nil alejandra`.

1. **The project needs it** → add it to the project's `flake.nix` devShell (see below) and commit it.
2. **One-off use** → run it ephemerally, no approval needed:
   - `nix shell nixpkgs#<pkg> -c <cmd>` (several packages: `nix shell nixpkgs#{a,b} -c …`)
   - `nix run nixpkgs#<pkg> -- <args>`
   - For newer versions, use `nixpkgs-unstable#<pkg>` (`nixpkgs` = the system's stable 26.05 channel).
3. **Reused across projects** → propose adding it to `home.packages` in `~/projects/think-nix/home.nix` for user tools,
   or to `configuration.nix` for system services/daemons. Prefer an existing `programs.<x>.enable` module over a raw package.
   Validate the change with `nixos-rebuild build`. Applying it (`sudo nixos-rebuild switch`) is the user's call.
4. **`nix profile add nixpkgs#<pkg>`**: only with the user's explicit OK, and only as a stopgap until step 3 lands.
   Say so, and remove it later (`nix profile list`, `nix profile remove <name>`).

Find packages with `nix search nixpkgs <term>` or <https://search.nixos.org/packages>.
**Never** use `nix-env -i`, `nix-channel`, `sudo npm i -g`, `pip install --user` / `--break-system-packages`,
`curl … | sh` installers, or writes into `/usr/local`. On NixOS they either fail or create invisible, unreproducible state.

## Per-project dev environments (flake + direnv)

- **Scaffold:** `nix flake init -t ~/projects/think-nix#devshell`. Then edit `packages`, add `.direnv/` to
  `.gitignore`, and run `git add flake.nix .envrc` (**flakes only see git-tracked files**), then `direnv allow`.
- **Agent shells don't auto-load direnv.** Run commands as `eval "$(direnv export bash)" && <cmd>`
  (prefix with `direnv allow &&` after `.envrc` changed or in a fresh checkout/worktree), or use `nix develop -c <cmd>`.
- Commit `flake.lock`. Use the `nixos-unstable` input. Pin runtime **majors** to match the deploy target
  (`nodejs_24`, `python313`, `jdk21`…), not generic `nodejs`/`python3`.
- **Node:** `pnpm` from the flake. **Python:** `uv` for venvs/deps (`uv init`, `uv add`, `uv run`) with the interpreter
  from the flake (set `UV_PYTHON_DOWNLOADS=never` in `shellHook`).
- **Services** (Postgres, Redis…): either start them in the devShell with data under a gitignored project dir
  (see `~/projects/zozahrady/flake.nix`) or use `podman-compose`.
- `mise` is installed, but only use it in projects that already have `mise.toml`/`.tool-versions`.

## Prefer modern approaches and latest versions

- **Pick the currently recommended upstream approach,** not the legacy one you saw most in training data.
  - Nix: flakes over channels/`shell.nix`; the `nix` CLI (`nix shell/run/develop/profile add`) over `nix-shell -p`/`nix-env`;
    NixOS/Home Manager options over hand-written dotfiles; `packages` over `buildInputs` in `mkShell`.
  - Other ecosystems: `pnpm` over npm/yarn for new Node projects; `uv` over pip/poetry/pipx (`uvx <tool>` for one-off CLIs);
    `pnpm dlx` / `npx -y <pkg>@latest` for one-off Node CLIs; `podman` over Docker; ESM + strict TypeScript.
- **Never trust version numbers or APIs from training data.** Look them up first:
  - nix: `nix eval --raw nixpkgs-unstable#<pkg>.version`
  - npm: `npm view <pkg> version`
  - PyPI: `curl -s https://pypi.org/pypi/<pkg>/json | jq -r .info.version`
  - GitHub: `gh release view -R <owner>/<repo>`

  Install with `@latest` (`pnpm add <pkg>@latest`, `uv add <pkg>`). For runtimes choose the current LTS/stable.
  Check current docs (Context7 MCP when configured, otherwise the official docs) before using APIs that may have changed.
- **Persist configuration in the narrowest declarative scope that fits:** project files (`flake.nix`, `package.json`,
  `pyproject.toml`, project `kilo.jsonc`) > user (`home.nix`) > system (`configuration.nix`). Don't rely on ad-hoc env vars or flags
  that the next session won't know about.

## Boundaries

- Ask before `sudo`, before anything that changes the running system (`nixos-rebuild switch/boot`, `nix profile add`,
  `systemctl` start/stop), and before destructive git operations.
- Commit/push only when asked. Use Conventional Commits (`feat(scope): …`, `fix(scope): …`, `chore: …`).
- Long-running processes (dev servers, watchers) must not block the session. Run them as background processes or leave them to the user.
- `~/projects/think-nix` is a **public** repo: never put secrets, tokens or private hostnames/IPs beyond what's already there.
