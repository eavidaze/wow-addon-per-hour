# Project instructions

## Communication and Git

- Communicate with the user in Portuguese.
- Use the simplified commit format `type: description`.
- Write the description in English, in the imperative, as one sentence on one line, without a body.
- Choose the prefix by purpose: `feat` for features, `fix` for bug fixes,
  `refactor` for restructuring without behavior changes, `docs` for documentation,
  `test` for tests, `ci` for workflows, and `chore` for maintenance.
  Example: `feat: revive Per Hour for WoW Forever`.
- Keep unrelated changes in separate commits, such as addon changes and local installation tooling.
- Never create commits, including when the user asks to commit.
- When the user mentions committing, stage only the related changes and provide only
  the `git commit` command for the user to review and execute.
- Push, create tags or publish releases only when explicitly requested.
- Preserve the user's existing changes and staging choices; leave edits available for review and testing.
- Follow the branch name requested by the user.
- Name working branches `<type>/<short-description>`, using the same types and purposes as commits:
  `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, and `chore`.
- Write branch descriptions in English, in lowercase, with words separated by hyphens.
  Examples: `feat/addon-improvements`, `fix/honor-tracking`, `docs/update-installation`.
- Choose the branch type by the main purpose of the work; individual commits may use other types.
- Never use `codex` in branch names.

## Code and documentation

- Target WoW Forever; use `per-hour.toc` as the source of truth for version and interface numbers.
- Name module Lua files in PascalCase, such as `Honor.lua` and `Experience.lua`.
- Match filename casing exactly in TOC/XML references, including when working on Windows.
- Keep the README short and focused on installation and use; put detailed instructions in `docs/`.
- Keep development files out of release ZIPs using `pkgmeta.yaml`.

## Validation and releases

- After changing Lua behavior or load references, run `lua tests/forever.lua` with Lua 5.1.
- Generate a local release ZIP with `.\scripts\package.ps1` when changing packaging.
- Keep simulation results distinct from actual in-game validation.
- Release tags use `v` followed by the version in `per-hour.toc`.
- Follow `docs/releasing.md` for publishing; publishing a GitHub Release triggers the upload workflow.
