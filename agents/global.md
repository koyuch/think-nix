# Global agent instructions (koyuch @ think-nix)

User-wide rules for every AI agent here. Project `AGENTS.md` adds to them and wins on conflict.
Source: `~/projects/think-nix/agents/global.md` (symlinked into each tool's config; edit the source, not the links).
Keep this file lean, since it is loaded on every turn. Put detail in skills.
Skills (`~/.agents/skills`, source `think-nix/agents/skills/`): **spec-driven-tdd** (features, new projects),
**decision-brainstorm** (choices with real alternatives), **project-bootstrap** (dev shell, hooks, CI, MCP, docs, Node/Python/Nix recipes).
Load one when its trigger matches. Tools without skill support: read the SKILL.md directly.
Custom primary modes (`research`, `spec`): `think-nix/agents/modes/`.

## How to work

- **Answers:** brief, lead with the result. Tables/mermaid instead of paragraphs where they help. No filler or praise.
- **Decisions:** no premature or majority-habit choices. With several reasonable options, run **decision-brainstorm**
  (comparison table with pros/cons, numbers, use cases, recommendation) and ask the user. Small reversible choices: decide, say so in one line.
- **Critical thinking:** verify instead of recalling, state assumptions, doubt your first answer, flag shaky premises.
- **Engineering:** Spec-Driven Development + TDD scaled to the change. SOLID, KISS, DRY, YAGNI, SoC. Record significant
  decisions as ADRs. Think as the whole team (product, architecture, security, ops), not only as the coder.
- **Commits:** after each logical green step (verified in practice — including after `nixos-rebuild switch` + runtime test when a system/HM change is involved), one concern each, tests with code, Conventional Commits. Follow the repo's flow
  (direct to `main` for personal/infra repos, else branch + PR). Never `--no-verify`. Push only when the repo's workflow expects it.
- **Agentic flow:** keep going through the next steps on your own. Stop only for a question the user must answer or a manual
  step only they can do. That includes `sudo`: run it, the user approves via the popup. Don't hand over commands you can run.
- Dev servers and watchers run as background processes, never blocking the session.

## This machine

- **NixOS 26.05 flake** in `~/projects/think-nix` (`/etc/nixos/*` link to it), user `koyuch`, zsh, KDE Plasma 6 Wayland.
  Home Manager runs as a NixOS module and owns many dotfiles (read-only symlinks): change them in `home.nix`.
- **Impermanence:** root is wiped every boot. Only `/home`, `/nix`, `/persist`, `/var/lib/libvirt` survive.
  Never configure `/etc`, `/var`, `/opt`, `/usr/local` by hand.
- **No FHS:** use `#!/usr/bin/env bash`. Prefer nixpkgs over foreign binaries (`nix-ld` is only a fallback).
- Podman replaces Docker (`docker` alias, `podman-compose`). Tailscale for LAN. Homelab: Pi 5 runs Forgejo (`git.tail5de296.ts.net`,
  org `homelab`) + K3s. Inventory `~/projects/homelab/repos.yml`, provisioning `~/projects/raspi5-lab`.
- **sudo** = fingerprint touch (password fallback). Agent shells have no tty and the touch prompt isn't visible, so run
  `asudo <cmd>` (sends a desktop notification, then `sudo -A`). Run it when needed, say *why* in one line first. Never bypass it.
- Commits are GPG-signed by default (pinentry may prompt). Never disable signing.

## Secrets (every repo, public or private)

- Never in git, prompts, logs or output. Commit only `.env.example`; `.env*` is gitignored.
- Keep them in `pass`; reference via `{ file:… }` / `{ env:… }` (no spaces in real config) or CI secret stores.
  Never read `~/.password-store` or print `pass` output.
- gitleaks runs in every repo's pre-commit hook and CI. A committed secret is leaked: tell the user, rotate first.

## Getting tools (declarative-first)

`command -v <tool>` first. Then:

1. Project needs it → add to the project's `flake.nix` devShell, commit.
2. One-off → `nix shell nixpkgs#x -c cmd` / `nix run nixpkgs#x`, no approval needed. Newer: `nixpkgs-unstable#x`
   (`nixpkgs` is the system's stable 26.05).
3. Reused across projects → propose a `home.packages` (user) or `configuration.nix` (system) change, check with `nixos-rebuild build`;
   the user applies it.
4. `nix profile add` only with the user's OK, as a stopgap; say so and remove it later.

Never: `nix-env -i`, `nix-channel`, global `npm -g`/`pip install --user`, `curl | sh`, writes to `/usr/local`.

## Projects: dev env, hooks, CI

- Scaffold: `nix flake init -t ~/projects/think-nix#devshell` (flake + direnv + prek hooks incl. gitleaks). Flakes see only git-tracked files: `git add` first.
- Agent shells don't load direnv: run `eval "$(direnv export bash)" && <cmd>` (also for `git commit`, so hooks find their tools).
  Prefix with `direnv allow &&` after `.envrc` changed or in a fresh checkout. Avoid `nix develop -c` (it trips the auto-approve rules).
- Hooks = `.pre-commit-config.yaml` via **prek**; CI runs the same checks and is a required check on `main`.
  Don't re-run what hooks/CI already run, except to fix a failure. Full recipe: **project-bootstrap**.
- `mise` only in projects that already use it.

## MCP

- Global (`home.nix` `programs.mcp`, mirrored in `~/.config/kilo/kilo.jsonc`): **context7** (current library docs, use before trusting
  remembered APIs), **nixos** (options/packages, use before writing Nix options).
- Project-specific MCPs go in the project config and its AGENTS.md. Auth via OAuth or `{ env:… }` / `{ file:… }`, never inline tokens.

## Modern and current

- Use the currently recommended upstream way, not the legacy one from training data (flakes, `nix` CLI, `pnpm`, `uv`, `ruff`, `prek`, `nixfmt`, podman).
- Never trust remembered versions/APIs. Look them up (`npm view`, PyPI JSON, `gh release view`, `nix eval nixpkgs-unstable#x.version`),
  install `@latest`, pick current LTS runtimes, check docs via context7.
- Put config in the narrowest declarative scope: project files > `home.nix` > `configuration.nix`. No ad-hoc env vars/flags.

## Boundaries

Ask before: `nixos-rebuild switch/boot`, `nix profile add`, `systemctl` start/stop, deleting data, force-push, history rewrites,
and anything that publishes (shared-branch push, releases, deploys) unless the repo's workflow says so.
