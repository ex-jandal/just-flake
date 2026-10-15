---
description: Bootstrap a new project end-to-end — clarify, plan for approval, then build, verify, document, and package. Stack-agnostic (Rust welcome).
---

# New Project

You are building a **new project from scratch** in this repository. The user has supplied this starting context (may be empty):

```
$ARGUMENTS
```

Follow the phases **in order**. Do not skip Phase 0 or Phase 1. Do not write production code before the user approves a plan.

---

## Phase 0 — Clarify (questions only, no code)

Before anything else, understand what is being built. Ask **in one batch**, then adapt based on the answers.

Ask only what you cannot infer from the repository and the supplied context. If a question has an obvious default, state the default and ask for confirmation rather than asking open-ended.

Always resolve these:

1. **What is it?** One sentence: the thing, and who it is for.
2. **What is the user's actual job?** What someone opens this to do. (Not a feature list — the outcome.)
3. **Interface surface.** CLI, TUI, GUI, web, library/SDK, service, plugin? If more than one, which is primary and which are secondary?
4. **Input → Output.** What goes in, what comes out. Include the file formats, protocols, or APIs involved.
5. **State.** Does it persist anything? Where? Is it read-only or read-write? Is a single user-editable config file wanted?
6. **Undo / reversibility.** Should destructive operations be undoable in-session? If yes, how far back?
7. **Distribution.** How will it be installed and launched: package manager, bundle, installer, desktop entry, container, library?
8. **Constraints.** Language/runtime preferences, must-use or forbidden libraries, target platforms, offline/network.
9. **License.** Which license(s). Dual licensing means both license files.
10. **Definition of done.** What must be true to call it finished — and what is explicitly out of scope for v1.

Then **stop and let the user answer.** Do not start scaffolding. If the user answered fewer than the above, ask the rest before proceeding.

Record the answers as a short **Product Brief** in your next message: the one-liner, the job, the surface, in/out, state, reversibility, distribution, constraints, license, done-criteria, and an explicit **Non-Goals** list. Non-Goals is the highest-value part — force it explicitly if the user did not.

---

## Phase 1 — Plan for approval (no code)

Produce a plan. **Do not create files yet.**

### 1.1 Architecture

- Module layout: name each file/crate/directory and the single responsibility of each. Keep the list short — a module that needs a paragraph of explanation is two modules.
- State model: the single in-memory structure the UI renders from, and how it is derived.
- I/O boundary: exactly which functions touch the filesystem, network, or external processes, and how they are isolated so they can be tested.
- Dependency list: every dependency with **one sentence on why it is required**. Anything you cannot justify in one sentence does not go in. Prefer the standard library and native platform features first.
- Deliberate omissions: the things you are choosing *not* to build in v1, and why.

### 1.2 Interaction blueprint

Design the interaction model concretely, not aspirationally. Specify:

- **Layout**: what panes/regions exist, what each shows, how they are split and resized.
- **Modal input**: the modes the app can be in (e.g. normal mode vs. command mode vs. filter mode), how the user enters and leaves each, and what keys are live in which mode. If a key means different things in different modes, say so explicitly per mode.
- **Key bindings**: the complete list, organized by mode, with the mnemonic rationale. Include navigation (line/half-page/full-page/top/bottom), selection, and focus movement.
- **Modal keymap**: every key, grouped by mode, in one table — with the mnemonic rationale, and how each conflict was resolved. This table must be the single source of truth for both the implementation and the documentation, so a test can assert they match. Required motions: `h`, `j`, `k`, `l`, `gg`, `G`, `w`, `b`, `/` — and any that do not apply to this surface, explicitly listed as unbound with the reason.
- **Command palette**: the command set, its canonical names, its aliases, argument-taking behaviour, and how completion/autocomplete works (candidates, prefix matching, selection movement, acceptance). Every command must be discoverable and listed in a help view.
- **Status/modeline**: which modeline fields are shown, which are user-toggleable, and the semantic colour of each. Must satisfy the Mandatory UI and interaction design section.
- **Workspaces**: the distinct views/modes, their order, their number-key bindings, their command aliases, and the labels shown on tabs.
- **Error surfacing**: how failures reach the user. A status line, not a dialog that blocks.

### 1.3 Data model and persistence

- The single config file: its format, its location resolution, every field with its default, and the behaviour when it is missing, malformed, or contains an unknown value (fail loudly vs. fall back — choose and justify).
- Read-only vs. read-write sources, and precedence when they disagree.
- Atomicity: how writes avoid corrupting a file if interrupted.
- Any file format being read or written (MIME databases, INI/desktop-entry files, TOML/YAML/JSON, binary formats): show a **representative real excerpt** of each, because real files in the wild are inconsistent and the parser must survive them.

### 1.4 Build, run, package

- Exact commands: build, run, test, lint/format, and typecheck. They must be real commands that work in this repo.
- Installation recipe: what gets installed where, and what registers it with the host system (launcher entry, desktop entry, MIME handler, protocol handler, man page, shell completion).
- Launcher metadata: app ID, display name, icon, categories, comment. The app ID and icon name must agree everywhere they appear.
- **Nix plan**: the full output list, the builder chosen and why, the architecture matrix (what you will actually build vs. only claim), the Home Manager option namespace with each option's default, and how declarative settings interact with an existing config file. Must satisfy the Mandatory NixOS packaging section.

### 1.5 Test plan

- Unit tests: which pure logic gets them, with concrete cases including boundaries and malformed input.
- Integration tests: the end-to-end flows against real files written to a **temporary directory**, with the real environment variables redirected to it.
- Manual/GUI verification: what to click and what must be visually true, plus how to capture evidence (screenshot command for the current display server).
- Nix verification: flake output evaluation, a clean `nix build`, the Home Manager module against a minimal test configuration, and a `nix flake check` run — all on temporary XDG directories.

### 1.6 Risks and unknowns

Name the things most likely to be wrong, with a concrete first check for each.

### 1.7 Work breakdown

An ordered checklist. Each item: what files it touches, what "done" means, and how it is verified. Keep items independently verifiable.

End the plan with an explicit **"Reply `approve` to begin, or tell me what to change."**

Stop there. Wait.

---

## Mandatory UI and interaction design

**These are product requirements, not suggestions.** They are not optional, not
deferrable to "later", and not traded away for convenience. Any project with a
user-visible interface — desktop GUI, TUI, or web UI — must satisfy all of them.
(A pure library or batch pipeline has no interface; skip only what does not
apply and say which parts you skipped and why.)

If the project's surface contradicts any rule here, **the requirement wins and
the plan changes** — raise the conflict in Phase 1 instead of quietly
deviating.

### Visual style

- Use the **Melange Dark** palette as the visual reference.
  Base `#292522`, raised `#34302C`, selection `#403A36`, text `#ECE1D7`,
  alt text `#C1A78E`, dim text `#867462`; accents red `#BD8183` / yellow
  `#E49B5D` / green `#78997A` / blue `#7F91B2` / cyan `#7B9695` /
  magenta `#B380B0`, with the brighter variant for emphasis.
- Restrained and text-oriented. Sharp, **square** corners.
- **No rounded corners, pill-shaped controls, rounded cards, gradients, or
  decorative effects.**
- Prefer thin borders, subtle separators, compact spacing, and clear visual
  hierarchy.
- Avoid unnecessary panels, excessive whitespace, oversized headings, and
  ornamental icons.
- Keep it simple, dense, readable, and consistent.

### Vim-style interaction

- Real modal interaction with clearly defined **Normal** and **Insert** modes.
  Any other modes (command line, search, confirm) must be named in the modeline
  and reachable/escapable predictably.
- Vim-style navigation for lists, menus, search results, and selectable items.
- Support familiar motions — `h`, `j`, `k`, `l`, `gg`, `G`, `w`, `b`, and `/`
  search — **where appropriate**. A motion that has no meaning in a given
  context is left unbound and documented as such; do not bind a key to a
  misleading action just to appear complete.
- Context-appropriate actions: `Enter` to open or confirm, `Esc` to cancel or
  return, `:` for command entry.
- Display the **current mode prominently in the modeline**.
- Show keyboard hints when useful, without filling the interface with permanent
  instructions.
- Every important operation must be reachable from the keyboard. Mouse support
  may supplement it but must never replace it.
- Do not assign Vim keys arbitrarily. Define and document a consistent keymap,
  resolve conflicting shortcuts deliberately, and make mode transitions
  predictable. The documented keymap and the implemented keymap are the same
  list — a test must assert that.

### Modeline

Provide a compact, **Doom Emacs-inspired modeline** that communicates the
current state. Render it as two justified groups — state on the left, position
and status on the right — not a single centred string.

It must carry, when relevant:

- current mode
- current workspace/view
- selection (e.g. `3/128`)
- item counts
- the current default/target item for the selection
- `USER` / `SYSTEM` scope, so the user always knows which file they are editing
- pending changes (e.g. uncommitted or undoable edits)
- search state (the active filter/query)
- theme
- operation status

Each field is rendered in a consistent semantic colour from the palette, and
each field can be toggled off individually via configuration. Fields that are
not relevant render as nothing rather than as placeholder text.

### Acceptance criteria

These are the gate. All six must hold before the project is called done:

1. **No rounded-corner styling anywhere** in the application.
2. Colours and semantic highlights follow Melange Dark consistently.
3. Core workflows can be completed **without a mouse**.
4. Vim motions and mode transitions behave **consistently across the whole
   application**, not just in the screen where you happened to test them.
5. The interface remains compact and functional rather than decorative.
6. **Verified in actual application screenshots or a running GUI — not merely
   by inspecting source code.**

---

## Mandatory NixOS packaging, flakes, and Home Manager

**This is a required part of the project. It must be implemented, tested, and
documented.** Never leave placeholder expressions, never treat packaging as a
future task, and never write it off as "someone else's step".

Substitute the project's own name for `<app>` throughout (package
`mimo_manager` → `programs.mimo-manager`, config path
`mimo_manager/config.toml`, and so on). If Phase 0/1 establishes that the
deliverable genuinely is not distributable as a Nix package — a pure library, a
document set — say so **in the plan and get it approved**. Do not assume the
exemption silently.

### 1. Flake outputs

Provide a reproducible `flake.nix` and a **committed** `flake.lock`.

The flake must expose:

- `packages.${system}.default` — the installable application.
- `apps.${system}.default` — launch with `nix run`.
- `devShells.${system}.default` — a reproducible development environment
  covering the toolchain, formatting, linting, tests, and any GUI build tools.
- `checks.${system}.default` — automated checks suitable for `nix flake check`.
- `formatter.${system}` — a Nix formatter.
- `homeModules.default` — the reusable Home Manager module.

Support at least `x86_64-linux` and `aarch64-linux` where the GUI framework and
its dependencies permit. **Verify each supported architecture rather than
claiming untested support.**

### 2. Package the application properly

- Prefer `rustPlatform.buildRustPackage` for a Rust project; the analogous
  native builder otherwise.
- Pin dependencies through both the flake lock and the language's own
  dependency lockfile.
- Use a reproducible vendor hash (or the equivalent supported mechanism), never
  an unpinned fetch.
- Include every runtime dependency the GUI framework needs.
- Install the executable plus desktop integration assets.
- Provide a valid `.desktop` entry and application icon when the framework and
  desktop integration support them.
- Ensure launching works on **Wayland** and under **Niri**, with X11
  compatibility where supported.
- Set required runtime environment variables and library paths **through the
  Nix packaging**. Do not depend on the developer's host environment.
- Never hardcode a home directory or any machine-specific path.
- The result must work with `nix build`, `nix run`, and installation via a Nix
  profile or NixOS `environment.systemPackages`.

### 3. Home Manager module

Provide a reusable module at a clearly documented path (e.g.
`nix/home-manager.nix`) and export it as `homeModules.default`.

Expose a documented option namespace — e.g. `programs.<app>` — with at least:

- `enable` — turn the application on or off.
- `package` — allow a package override, defaulting to the flake's own package.
- `settings` — optionally declare application settings as a typed Nix
  attribute set.
- `configFile` — or an equivalent documented option, if a user-supplied config
  file is useful.

When enabled, the module installs the application into `home.packages`.

Manage the TOML file declaratively when `settings` are supplied, preserving the
application's documented path: `$XDG_CONFIG_HOME/<app>/config.toml`, falling
back to `~/.config/<app>/config.toml`.

Do not generate competing configuration files, and do not overwrite
user-managed configuration unexpectedly. **Define and document how declarative
settings interact with an existing configuration file.**

Keep the module reusable: a user must be able to import it into their own Home
Manager configuration **without** importing the project's development
environment.

### 4. NixOS usage

Document both installation methods.

**System package:**

```nix
environment.systemPackages = [
  inputs.<app>.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```

**Home Manager module:**

```nix
{
  imports = [
    inputs.<app>.homeModules.default
  ];

  programs.<app>.enable = true;
}
```

Provide a **complete flake input example** showing how to add the project to an
existing NixOS/Home Manager flake. Explain `inputs.<app>.inputs.nixpkgs.follows =
"nixpkgs"` and compatibility with the user's pinned Nixpkgs revision.

Never require users to copy the application's source into their own repository.

### 5. Development workflow

Document these, and confirm each one actually works:

```sh
nix develop
nix build
nix run
nix flake check
nix fmt
cargo test
cargo clippy --all-targets --all-features -- -D warnings
```

Adapt the last two to the project's language. The development shell is
**optional** for running the application, not a prerequisite for using it. No
`devenv` dependency.

### 6. Packaging and module verification

Test the Nix integration **independently of the developer's existing system
configuration**.

- Evaluate the flake outputs; confirm the package and Home Manager module are
  exposed correctly.
- Build the package in a clean Nix build environment.
- Test the Home Manager module against a minimal test configuration.
- Confirm enabling the module installs the application, and disabling it does
  not.
- Confirm a custom package override and declarative settings behave correctly.
- Test the installed executable and the desktop entry where applicable.
- Run every test with **temporary XDG config and data directories**, so no test
  ever touches the developer's real associations or state.
- Run `nix flake check` and fix packaging, evaluation, and test failures rather
  than suppressing them without justification.

### 7. Documentation and definition of done

Document the flake outputs, supported architectures, package installation,
Home Manager integration, configuration options, development workflow, and
troubleshooting.

Nix integration is complete **only when** the package builds, the app launches,
the Home Manager module evaluates and behaves correctly, and the documented
commands have been verified. **Report explicitly any architecture or GUI
integration you could not test.**

### Acceptance criteria

1. `nix flake check` passes with no unjustified suppressions.
2. The package builds and the application launches from `nix run`, with no
   dependence on host environment variables.
3. Every advertised architecture is either built and launched, or explicitly
   reported as untested.
4. The Home Manager module enables, disables, honours package overrides, and
   writes declarative settings to the documented config path — each verified
   against a minimal test configuration.
5. Tests used temporary XDG directories; the developer's real state is
   unchanged.
6. A user's Home Manager flake can import `homeModules.default` and enable the
   program with the documented snippet, without copying any source.

---

## Phase 2 — Build

Only after approval.

### 2.1 Working order

Follow the Phase 1.7 checklist in order. Implement one checklist item at a time and verify it before starting the next. Do not batch several items into one unverified lump.

### 2.2 First-slice rule

Get **one vertical slice working end to end** as early as possible — real I/O, real rendering, real output — even if it covers one command and one pane. A thin slice that works beats a wide skeleton that runs. Then widen.

### 2.3 Non-negotiable engineering rules

These are guardrails. Violating them is a defect, not a style preference.

**Smallest correct change.**
- Prefer deletion to addition. The best change is the one that makes code unnecessary.
- Stop at the first rung that works, in this order:
  1. Does this need to exist at all? Speculative need → skip it and say so in one line.
  2. Does the codebase already have this? A helper, util, type, or pattern a few files over → reuse it.
  3. Does the standard library do it?
  4. Does a native platform feature do it? (A native date input over a picker library. CSS over JS. A database constraint over application code.)
  5. Does an already-installed dependency do it? Never add a dependency for what a few lines can do.
  6. Can it be one line?
  7. Only then: the minimum code that works.

**No speculative abstraction.**
- No interface with one implementation. No factory for one product. No config for a value that never changes. No scaffolding "for later" — later can scaffold for itself.
- Introduce an abstraction only when there is a second real caller or a test that needs it.

**Follow existing conventions.**
- Read the surrounding code before writing. Match its naming, error handling, module boundaries, naming style, and comment density. Do not introduce a second style.
- New code should read like the code around it.

**Root-cause fixes, not symptom patches.**
- When fixing a bug, find the **root cause** first. Grep every caller of the function you are about to change. A guard inside the shared function is a smaller diff than a guard in every caller, and it fixes every sibling path instead of only the one a report named.
- Patching only the path the ticket describes leaves every other caller still broken. Find them all.

**One runnable check for non-trivial logic.**
- Any branch, loop, parser, or money/security path leaves behind **one** runnable check that fails if the logic breaks. An assert-based self-check or one small test file. No framework ceremony, no fixtures directory, no per-function suites unless asked.
- Trivial one-liners need no test. Tests are not exempt from the smallest-correct-change rule.

**Honest completion claims.**
- Never report a task complete without having run the verification in this session. If a check did not run, say it did not run. Do not claim passing tests you did not execute. If you are blocked, say so and name the blocker.
- Never hide a known limitation. A correct statement of what is *not* done is worth more than a confident wrong summary.

**Deliberate simplifications get marked.**
- If you ship a known-ceiling shortcut (a global lock, an O(n²) scan, a naive heuristic, a fixed retry count), mark it at the point of use with a short comment naming the ceiling and the upgrade path.
- Hardware is never ideal on paper: a real clock drifts, a real sensor reads off. Leave the calibration knob, not just the code.

### 2.4 Correctness rules that are never negotiable

- Validate all input at trust boundaries — files, CLI args, environment, network responses, subprocess output.
- Handle errors that prevent data loss: never truncate, never partially write a user file, never destroy data on a failed operation.
- Never log or print secrets, tokens, keys, or credential values.
- Accessibility basics are not optional: keyboard reachability, focus order, visible focus, labels on controls, contrast that passes WCAG AA.
- Anything the user explicitly requested is never simplified away. If you simplify a requested feature, that is a deviation you must surface, not a silent choice.

### 2.5 UI rules

These supplement, and never relax, the Mandatory UI and interaction design section.

- Every interactive surface covers its required states: empty, loading, error, offline/no-results, permission-denied, success, and long content that overflows. A missing state is an incomplete screen, not a deferred feature.
- Keyboard-first if the app has a keymap at all: every mouse action has a key equivalent.
- No layout shift on load. Reserve space for content that arrives later.
- Text must not be clipped or ellipsized into uselessness. If it overflows, wrap or scroll.
- The **focused** region must be visually distinguishable from the unfocused one at a glance. Keyboard users cannot feel focus; they must be able to see it.
- When a theme is switchable, switching must repaint in place — no restart, no flash of the previous theme.
- If the widget toolkit's default theme draws rounded corners, pills, gradients, or shadows, override them explicitly. The toolkit default is not a licence; check it in a screenshot.

---

## Phase 3 — Verify

Do not proceed to documentation until verification actually passes.

1. **Format** — the project's formatter, on the whole tree. Clean output, no errors.
2. **Lint** — the project's linter with warnings escalated to errors (`-D warnings` where supported). Fix, do not suppress.
3. **Typecheck** — if the language has one, as a separate gate.
4. **Tests** — the full suite. Report the real pass/fail counts. If a test is flaky, fix the flakiness or report it as a known issue; do not delete the assertion to get green.
5. **Build** — a clean release-mode build of the real artifact, not just the dev profile.
6. **Run it for real** — launch the actual binary/app with a redirected, temporary environment. Exercise the main flow. Then close it cleanly.
7. **GUI check** — drive the real UI: launch, interact, screenshot, inspect the screenshot, fix what it reveals, re-check. Iterate until the rendered result matches the plan. A UI change that was not visually verified is unverified.
8. **Acceptance gate** — walk all six acceptance criteria in the Mandatory UI and interaction design section one by one. For each, state **how** it was verified and attach the evidence (screenshot, key-event log, or test name). Criterion 6 explicitly forbids concluding "compliant" from reading the source: if you did not see it rendered, you did not verify it.
9. **Keyboard-only pass** — complete the core workflows with the mouse unused. If any step needs a pointer, that is a defect; fix it or report it.
10. **Nix verification** — evaluate the flake outputs, build in a clean Nix build environment, exercise the Home Manager module against a minimal test configuration (enable, disable, package override, declarative settings), and run `nix flake check`. Use temporary XDG directories throughout. Fix packaging, evaluation, and check failures; do not suppress them without a written justification.
11. **Nix acceptance gate** — walk all six acceptance criteria in the Mandatory NixOS packaging section, and state explicitly which architectures and GUI integrations you could **not** test. Untested is a reportable result, not a silent pass.

If a linter is not configured in this project, **say so explicitly** rather than implying the check passed.

---

## Phase 4 — Document and package

### 4.1 README

- Centered project logo/icon image at the very top.
- One-sentence tagline immediately under it.
- Then: what it is, who it is for, why it exists.
- Then: install, build, run, test. Copy-pasteable commands only.
- Then: usage — the keybindings, the command list, the config file reference with every field and its default.
- Then: how the packaging works (what installs where, what registers it with the host).
- Then: **Nix** — the flake outputs, the supported architectures, installation as a NixOS system package and via the Home Manager module (with the complete flake input example), the Home Manager option reference with defaults, and the development workflow commands.
- Then: troubleshooting — the failures a user actually hits (platform mismatch, missing Wayland session variable, icon not appearing, config path not picked up, `nix flake check` failure).
- Then: license. Then: screenshots showing the real UI.

Every command in the README must have been run. No aspirational commands.

### 4.2 License

- Add the license file(s) named by the brief. Dual licensing → both files, with copyright holder and year.
- Reference the license in the README and in the packaging metadata.

### 4.3 Packaging

- Launcher/desktop entry file with: app ID, name, generic name, comment, icon name, categories, executable path, and the terminal/desktop hints that apply.
- Icon asset at a size the platform expects, named to match the app ID.
- Install rule in the packaging manifest that places the binary, the entry, and the icon in the correct per-user or system paths.
- Verify the icon name in the launcher entry and the icon filename agree exactly. A mismatch produces a silent no-icon app.
- Verify the app ID used by the launcher matches the one the app registers at runtime.
- `flake.nix` and a committed `flake.lock` exposing every output in the Mandatory NixOS packaging section; `nix/home-manager.nix` exported as `homeModules.default`. All required, none left as placeholders.
- No `devenv` dependency, and the dev shell stays optional for *running* the application.

### 4.4 Comments and in-code docs

- Comment the **why**, not the what. Match the surrounding comment density — do not flood a codebase that is otherwise comment-free.
- No commented-out code. No TODO without an owner or a condition.

### 4.5 Scope discipline

Do not add features that were not requested, no matter how obviously useful they seem. If you spot something worth doing, **list it at the end** as a suggestion and let the user decide.

---

## Phase 5 — Hand off

Close with a short report:

1. **What was built** — one line per checklist item, marked done.
2. **Verification evidence** — the exact commands run and their real results (pass counts, clean lint, clean fmt). If something did not run, say so plainly.
3. **Acceptance criteria** — every criterion from the Mandatory UI and Mandatory NixOS sections, each with its evidence. Anything you could not verify must be reported as **unverified**, not as passed.
4. **Untested matrix** — architectures and GUI integrations you could not build or launch, named explicitly.
5. **What was deliberately skipped** — from the plan's omissions, plus anything you found and left alone.
6. **Suggested next steps** — optional, clearly marked as optional.
7. **Commit status** — say whether you committed. Do not commit unless the user asked you to.

**Never commit without being asked.** When the work is verified, stop and ask.

---

## Safety rules — non-negotiable, every phase

- **Never touch real user state during development or tests.** Never write to the actual `~/.config`, `~/`, `$XDG_CONFIG_HOME`, `~/Library`, `/etc`, or system paths. Redirect every environment variable that controls where state lands into a temporary directory, and clean up after.
- Tests write only into temp directories they create. No test may depend on or mutate the developer's real machine.
- **Only terminate processes you started.** Never kill by broad process-name pattern — that pattern will match the user's own instances. Record the PID when you launch something and kill that specific PID. If you did not record a PID, do not kill it.
- **Prefer reversible actions.** Back up before overwriting something you did not create. Never delete, force-push, reset, or rewrite history without explicit instruction.
- **Never commit or push** unless explicitly asked. Inspect `git status`, `git diff`, and recent log before any commit; stage only the intended files; never stage secrets.
- **Never install system packages, global packages, or system services** without asking first.
- **Never invent a URL, API name, config key, or file path.** Verify it exists before relying on it. If you cannot verify it, say so and mark it unverified.
- **Ask before any action that is hard to reverse or reaches outside the local machine.**
- If you find yourself blocked, stop and ask a specific question. Do not guess and proceed.

---

## Tone

Be direct. Prefer the smallest thing that works and say plainly what you skipped and when it would need to be added. Report honestly — an accurate "this part is not done" is more valuable than a confident wrong summary. When you are uncertain, say which part is verified and which is not.

