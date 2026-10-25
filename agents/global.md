# Global agent instructions (koyuch @ think-nix)

User-wide rules for every AI agent on this machine (Kilo, opencode, Gemini/Antigravity, Claude, pi, aider).
Project `AGENTS.md` files add to these rules, and their rules win when the two conflict.
Source of truth: `~/projects/think-nix/agents/global.md`. Home Manager symlinks it into each tool's config dir,
so edit that file, never the symlinks.
On-demand skills live in `~/.agents/skills` (source: `think-nix/agents/skills/`). Load them when their trigger matches:
**spec-driven-tdd** (features/projects), **decision-brainstorm** (choices with real alternatives),
**project-bootstrap** (dev shell, hooks, CI, MCP, docs layout). Tools without skill support should read
the SKILL.md files directly.
Custom primary agent modes (`research`, `spec`) live in `think-nix/agents/modes/` (symlinked to `~/.config/{kilo,opencode}/agents`).

## How to work

- **Answers:** brief, clear, to the point. Lead with the result. Use tables for comparisons and mermaid diagrams for
  flows/architecture where they replace paragraphs. No filler, no praise, no restating the question.
- **Decisions:** don't decide prematurely or by majority habit. When there are several reasonable options, run the
  **decision-brainstorm** skill: a comparison table with pros/cons, numbers and use cases, plus a recommendation. Then ask the
  user (the question tool when available) instead of picking silently. Small, reversible choices: decide and say so in one line.
- **Critical thinking:** verify instead of recalling, state your assumptions, doubt your own first answer, and say when
  you're unsure or when the user's premise looks wrong. Prefer evidence (docs, source, a quick experiment) over confidence.
- **Engineering:** Spec-Driven Development + TDD (spec → plan → tasks → red/green/refactor), scaled to the change.
  Apply SOLID, KISS, DRY, YAGNI and separation of concerns; prefer the simplest design that meets the spec. Record
  significant decisions as ADRs. Think like the whole team: product (who is this for, what's the smallest valuable
  slice), architecture (boundaries, contracts, failure modes), security, operations (observability, rollback).
- **Commits:** commit after each logical, green step. One concern per commit, with tests and code together, using Conventional
  Commits (`feat(scope): …`, `fix(scope): …`, `refactor:`, `test:`, `docs:`, `chore:`, `style:`). Follow the repo's flow:
  work directly on `main` for personal/infra repos when that's the established practice, otherwise use a branch, then a PR.
  Never `--no-verify`, never commit unrelated changes. Push and open a PR when the user or the repo's workflow expects it.
- Long-running processes (dev servers, watchers) must not block the session. Run them as background processes.

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
- **Homelab:** Raspberry Pi 5 (`raspi5`) runs Forgejo (`https://git.tail5de296.ts.net`, org `homelab`) with Actions,
  plus K3s. Repo inventory: `~/projects/homelab/repos.yml`. Provisioning: `~/projects/raspi5-lab`.
- **sudo:** fingerprint touch (password fallback). You may run `sudo` when the task needs it. The touch prompt is
  the user's approval, so state in one line *why* right before the command. Never try to bypass it.
- Git commits are **GPG-signed by default**: never disable signing. A commit may wait on a pinentry prompt.
- Projects live in `~/projects/<name>`.

## Secrets (all repos, public or private)

- Never put secrets, tokens, keys, passwords or private credentials in git, prompts, logs or command output.
  Only `.env.example` (placeholders) gets committed; `.env*` is gitignored.
- Store them in `pass` (GPG). Reference them from config instead of inlining: `{ file:… }` / `{ env:… }` (without spaces) in Kilo/opencode,
  CI secret stores, gitignored files. Never read `~/.password-store` or print `pass` output.
- Every repo runs **gitleaks** in its pre-commit hook and CI (see below). If a secret was ever committed, treat it as leaked:
  tell the user and rotate it first.

## Getting tools: declarative-first ladder

Before using a tool, check whether it's already available: `command -v <tool>`. Already on PATH:

| Area | Tools |
|---|---|
| Search/files | `rg fd fzf bat eza tree dust duf ncdu file p7zip rsync` |
| Data | `jq yq` |
| Dev | `git gh just make pre-commit uv node python3 jdk mise direnv` |
| Nix | `nil alejandra nix-tree mcp-nixos` (dev shells add `prek nixfmt deadnix statix`) |
| HTTP/net | `curl xh httpie wget dog nmap socat iperf3 mtr tailscale` |
| Ops | `kubectl helm k9s awscli2 ansible podman podman-compose dive btop procs lsof strace` |

Useful ephemeral extras (`nix shell nixpkgs#…`): `ast-grep` (structural search/rewrite), `difftastic`/`delta` (diffs),
`hyperfine` (benchmarks), `tokei` (code stats), `sd` (sed alternative), `watchexec`, `shellcheck`/`shfmt`, `actionlint`,
`typos` (spellcheck), `glow` (render markdown), `git-cliff` (changelogs).

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

Find packages with `nix search nixpkgs <term>`, the **nixos MCP**, or <https://search.nixos.org/packages>.
**Never** use `nix-env -i`, `nix-channel`, `sudo npm i -g`, `pip install --user` / `--break-system-packages`,
`curl … | sh` installers, or writes into `/usr/local`. On NixOS they either fail or create invisible, unreproducible state.

## Per-project dev environments, hooks and CI

- **Scaffold:** `nix flake init -t ~/projects/think-nix#devshell`. This creates `flake.nix`, `.envrc`, `.gitignore` and
  `.pre-commit-config.yaml`. Then run `git add -A` (**flakes only see git-tracked files**) and `direnv allow`.
- **Agent shells don't auto-load direnv.** Run commands as `eval "$(direnv export bash)" && <cmd>`
  (prefix with `direnv allow &&` after `.envrc` changed or in a fresh checkout/worktree), or use `nix develop -c <cmd>`.
  Run `git commit` the same way, so the hooks can find their tools.
- Commit `flake.lock`. Use the `nixos-unstable` input. Pin runtime **majors** to match the deploy target
  (`nodejs_24`, `python313`, `jdk21`…), not generic `nodejs`/`python3`.
- **Node:** `pnpm` from the flake. **Python:** `uv` for venvs/deps (`uv init`, `uv add`, `uv run`) with the interpreter
  from the flake (set `UV_PYTHON_DOWNLOADS=never` in `shellHook`).
- **Services** (Postgres, Redis…): either start them in the devShell with data under a gitignored project dir
  (see `~/projects/zozahrady/flake.nix`) or use `podman-compose`.
- **Hooks:** `.pre-commit-config.yaml` run by **prek**, with `language: system` tools from the devShell.
  - pre-commit (fast): hygiene, gitleaks, formatter, linter.
  - pre-push / CI: tests.
  - Existing husky/lint-staged setups (Node) can stay, but add gitleaks.
- **CI runs the same checks** (`nix develop -c prek run --all-files`, plus tests and build), as a required check on `main`.
  Homelab repos use Forgejo Actions (`.forgejo/workflows/`); GitHub-hosted ones use GitHub Actions.
  Details: the **project-bootstrap** skill.
- Don't re-run checks that hooks/CI already run automatically, unless you're fixing a failure.
- `mise` is installed, but only use it in projects that already have `mise.toml`/`.tool-versions`.

## MCP servers

- **Global** (declared in `think-nix/home.nix` `programs.mcp`, mirrored in `~/.config/kilo/kilo.jsonc`):
  - `context7`: current library docs. Use it before relying on APIs that may have changed.
  - `nixos`: NixOS / Home Manager options and packages. Use it before writing Nix options.
- **Project-specific** servers (database, hosting, design, browser, …) go in the project's config
  (`kilo.jsonc` / `opencode.json` / `.mcp.json`) and get documented in its AGENTS.md. When a project would clearly
  benefit from one, propose it. Auth via OAuth or `{ env:… }` / `{ file:… }` references, never inline tokens.

## Prefer modern approaches and latest versions

- **Pick the currently recommended upstream approach,** not the legacy one you saw most in training data.
  - Nix: flakes over channels/`shell.nix`; the `nix` CLI (`nix shell/run/develop/profile add`) over `nix-shell -p`/`nix-env`;
    NixOS/Home Manager options over hand-written dotfiles; `packages` over `buildInputs` in `mkShell`; `nixfmt` (official style).
  - Other ecosystems: `pnpm` over npm/yarn for new Node projects; `uv` over pip/poetry/pipx (`uvx <tool>` for one-off CLIs);
    `pnpm dlx` / `npx -y <pkg>@latest` for one-off Node CLIs; `ruff` for Python lint/format; `prek` over pre-commit;
    `podman` over Docker; ESM + strict TypeScript.
- **Never trust version numbers or APIs from training data.** Look them up first:
  - nix: `nix eval --raw nixpkgs-unstable#<pkg>.version`
  - npm: `npm view <pkg> version`
  - PyPI: `curl -s https://pypi.org/pypi/<pkg>/json | jq -r .info.version`
  - GitHub: `gh release view -R <owner>/<repo>`

  Install with `@latest` (`pnpm add <pkg>@latest`, `uv add <pkg>`). For runtimes choose the current LTS/stable.
  Check current docs (Context7 MCP, otherwise the official docs) before using APIs that may have changed.
- **Persist configuration in the narrowest declarative scope that fits:** project files (`flake.nix`, `package.json`,
  `pyproject.toml`, project `kilo.jsonc`) > user (`home.nix`) > system (`configuration.nix`). Don't rely on ad-hoc env vars or flags
  that the next session won't know about.

## Boundaries

- Ask before anything that changes the running system or is hard to undo: `nixos-rebuild switch/boot`, `nix profile add`,
  `systemctl` start/stop, deleting data, force-push, history rewrites, or anything that publishes (push to a shared
  branch, releases, deploys) unless the repo's workflow says so.
