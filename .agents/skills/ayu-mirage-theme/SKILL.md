---
name: ayu-mirage-theme
description: Audit a developer-environment or dotfiles repository and apply Ayu Mirage consistently to supported editors, terminals, and TUIs. Use when adding, restoring, checking, or extending Ayu Mirage theming, including Ghostty, Kitty, Zed, VS Code, Neovim/AstroNvim, Tuicr, Herdr, and newly added tools.
---

# Ayu Mirage Theme

Apply Ayu Mirage wherever the target supports it. Preserve unrelated settings and use the host terminal palette when an application has no native Ayu Mirage theme.

## Workflow

1. Inspect repository instructions and working-tree status before editing.
2. Search configuration, setup scripts, package manifests, documentation, and tests for:
   - `theme`, `color`, `appearance`, and `colorscheme`
   - known theme names such as Catppuccin, GitHub, Tokyo Night, and Ayu
   - installed editors, terminals, multiplexers, and TUIs
3. Determine support from installed command help or authoritative upstream documentation. Browse current official sources when identifiers or support may have changed.
4. Prefer native Ayu Mirage support. Otherwise use a documented terminal/ANSI inheritance mode. Do not invent unsupported theme names.
5. Update installer logic, declarative configuration, examples, and relevant tests together.
6. Validate syntax, run focused tests, run `git diff --check`, and report unrelated pre-existing failures separately.

## Known mappings

Use these mappings when they remain supported:

| Tool | Configuration |
| --- | --- |
| Ghostty | `theme = Ayu Mirage` |
| Kitty | `kitten themes --reload-in=none "Ayu Mirage"` |
| Zed | Set dark mode and both theme variants to `"Ayu Mirage"` when using the object form |
| VS Code | Install `teabyii.ayu`; set `workbench.colorTheme` to `"Ayu Mirage"` and `workbench.iconTheme` to `"ayu"` |
| Neovim/AstroNvim | Use `Shatur/neovim-ayu`, set `opts = { mirage = true }`, and select the `ayu` colorscheme through AstroUI |
| Tuicr | Set `theme = "ayu-mirage"` and `appearance = "dark"` |
| Herdr | Set `[theme] name = "terminal"` so its UI inherits the Ayu Mirage terminal ANSI palette |

Treat Herdr's `terminal` setting as a fallback, not native Ayu Mirage support. If Herdr later adds a documented native preset, prefer that preset.

## Repository conventions

In this repository:

- Store application configs under `config/<application>/`.
- Store VS Code settings under `vscode/settings.json` and link them separately to the macOS VS Code User directory.
- Keep extension installation and Kitty theme activation in `mac-setup`.
- Update `tests/mac-setup-test.sh` when setup behavior or synchronized config changes.
- Keep `modern-setup.md` examples consistent with executable configuration.

Use `apply_patch` for edits. Do not discard unrelated user changes.

## Verification

Run the narrowest useful checks first:

```sh
git diff --check
sh tests/config-test.sh
sh tests/mac-setup-test.sh
```

Also validate tool-specific configuration when a suitable command exists. A Node.js `DEP0169` warning during `code --install-extension teabyii.ayu` is non-fatal when VS Code reports that the extension installed successfully.

## Activation handoff

At the end, ask the user to execute:

```sh
mac-setup config
```

Explain that this synchronizes the repository configuration into the live application config locations, installs the VS Code Ayu extension when needed, and activates the Kitty theme. Optionally offer to run the command for the user. Run it only after the user authorizes changing their live configuration.

In the handoff, distinguish:

- native Ayu Mirage integrations,
- terminal-palette fallbacks,
- unsupported applications,
- validation failures unrelated to the theme changes.
