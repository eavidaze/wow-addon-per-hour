---
name: per-hour-prepare-release
description: Automatically prepare a Per Hour version bump for WoW Forever, synchronize documentation, validate the ZIP, commit the release changes, push and create its PR into main. Use for release preparation through PR creation; use per-hour-publish-release for merging and publication.
---

# Per Hour release preparation

Execute release preparation through creation of a PR into `main`. Communicate
in Portuguese and keep project documentation in its existing language. The user
has authorized this workflow to run automatically, including the release commit,
push and PR creation. A normal invocation executes these steps instead of asking
the user to run commands or confirm routine decisions. Ask only when a material
doubt or ambiguity cannot be resolved from the repository and session context.
This stage ends at the PR; do not automatically start `$per-hour-publish-release`.
Discussing or editing the skill does not invoke the release workflow.

## Establish scope and version

- Read `AGENTS.md`, `per-hour.toc`, `docs/releasing.md`,
  `docs/curseforge-listing.md`, `README.md`, `pkgmeta.yaml`,
  `scripts/package.ps1` and `.github/workflows/release.yml`.
- Inspect staged and unstaged changes before editing. Preserve unrelated work
  and staging choices. Reuse the current suitable working branch. On `main` or a
  detached HEAD, create a working branch following `AGENTS.md` before committing;
  do not rename an existing working branch or push release changes directly to main.
- Inspect the changes since the previous published **Forever** release, including
  relevant work on the current branch. Verify actual behavior in code and tests;
  commit subjects alone are not evidence that a feature exists.
- Distinguish a published release from a tag or a prepared bump. Old tags such as
  `1.1.2` may belong to the legacy addon; do not compare them blindly with Forever
  versions. Use read-only GitHub release information when needed and available.
  If the baseline cannot be confirmed, state the comparison used and its limitation.
- Separate product capabilities from UX refinements before choosing the bump.
  A feature lets the player track something new, perform a new action or configure
  a new behavior. Making existing states or data easier to see is UX: activity
  indicators, colors, sizing, alignment and reorganizing existing tooltip information
  are not new features merely because a new UI element was added.
- Honor an explicit target version. Otherwise explain the choice: patch for fixes
  and UX refinements, minor for new capabilities, major for incompatible changes.
  An activity indicator alone does not justify a minor bump. Classify the actual
  behavior rather than the wording of a `feat` commit, and do not silently revise
  an already approved version when reclassifying its release notes.
- Treat `per-hour.toc` as the version source of truth and preserve `-forever`.
  If an unpublished target version is already prepared, finish its documentation
  and validation instead of automatically bumping it again. Never silently replace
  an explicit version or reuse an already published version for different contents.
- Change only `## Version` for a normal bump. The client `## Interface` value is
  independent and must remain unchanged unless client compatibility is in scope.
  Derive the release tag as `v<base-version>`, without `-forever`: for example,
  TOC `1.1.1-forever` maps to tag `v1.1.1`. Strip only the trailing `-forever`
  when deriving this tag; preserve the TOC version and existing release-notes
  filenames. The workflow's `-g forever` makes the packager append `-forever`
  to the ZIP filename and upload label when absent; it does not change the tag.
  Do not create the tag during preparation.

## Synchronize release documents

- Always review `docs/curseforge-listing.md` in every release preparation,
  including when a version is already prepared or its release commit is reused.
  Compare the project name, summary and full description with actual release
  behavior and current usage instructions. An existing edit or an apparently
  up-to-date listing does not replace this review. Update new, changed and removed
  capabilities and affected instructions; remove obsolete steps. Change only
  fields that need it, and keep the file unchanged when the review confirms it
  already describes the release correctly.
- Keep `README.md` short and focused on installation and usage. Put detailed
  behavior, limitations or release instructions in `docs/`.
- Keep product descriptions distinct from release notes. The CurseForge feature
  list should describe meaningful player capabilities, not advertise cosmetic
  refinements such as the activity diamond. Do not add a README bullet for each
  visual change. Explain a UX change in usage instructions only when players need
  it to understand or operate the addon; otherwise record it in release notes.
- Create or update `docs/releases/<version>.md` with user-facing release notes
  derived from the actual release diff. Include only applicable additions,
  changes, fixes, compatibility information and known limitations. Record automated
  validation separately from in-game validation and never imply gameplay testing
  from simulation results. Put UX refinements under **Changed**; reserve **Added**
  for new capabilities rather than every new visual element. Do not rewrite notes
  for an already published release.
- Review version examples and publishing instructions in `docs/releasing.md`
  against the current workflow and target version. Update stale instructions when
  relevant, using `v<base-version>` without `-forever` in release-tag examples;
  do not modify CI, credentials or packaging rules merely to prepare a bump.
- Local CurseForge listing text is copy-ready content. The release workflow uploads
  the addon ZIP but does **not** synchronize project name, summary or description.
  Report any optional listing fields that differ, without making a routine
  release depend on the user copying them. Do not edit the website unless updating
  the listing itself was requested.

## Validate the release candidate

- Run `lua tests/forever.lua` with Lua 5.1. Verify the interpreter version. If the
  `lua` command is unavailable, an existing Lua 5.1 executable or `lupa.lua51`
  running `dofile("tests/forever.lua")` is acceptable; report the actual runner.
  If no compatible runtime is available, report that validation as pending.
- Generate the local ZIP using `.\scripts\package.ps1`. Open the resulting ZIP
  and verify its versioned filename, `per-hour/` root, and packaged TOC version
  and Interface against the source TOC.
- Verify TOC and nested XML load references resolve to files in the ZIP with exact
  filename casing. Check that development files such as tests, scripts, docs,
  skills and `AGENTS.md` are excluded. Respect the existing `pkgmeta.yaml` rules;
  report a packaging defect and fix it only within the requested scope.
- Run `git diff --check` and review the final diff, including existing staged work.
  Finish local preparation even if authentication or PR creation is unavailable.

## Commit, push and create the PR

- Before committing or reusing a release commit, confirm that the CurseForge
  listing review is complete alongside the README and release-notes review.
- Review the final release changes internally, then stage and commit only changes
  belonging to this preparation. Use the repository's one-line English imperative
  format, for example `chore: bump version to <toc-version>`. The user's automatic
  release-workflow authorization is a narrow exception to the general no-commit
  rule in `AGENTS.md`; it does not authorize unrelated commits.
- Use explicit paths and isolate the release commit from unrelated staged work
  while preserving the user's index and working-tree changes. Never blindly use
  `git add .`, `git commit -a`, reset or stash the user's work. If unrelated edits
  are inseparable from the release edits and their inclusion is unclear, ask that
  specific question before committing them.
- If the release is already committed, reuse that commit rather than create an
  empty or duplicate bump. Verify tests, ZIP and notes correspond to the actual
  committed content; account for checkout line-ending normalization when comparing.
- Check `gh auth status` in the real execution environment and reuse a valid
  session. A sandbox may report an invalid token while the host CLI is authenticated
  through the keyring; verify with a read-only host check when available before
  diagnosing missing authentication. Do not run or suggest login routinely or
  expose credentials. Handle ordinary CLI or network failures internally.
- Execute `git push --set-upstream <remote> <branch>` for the prepared branch.
  Stop dependent operations if push fails; do not force-push or overwrite remote
  changes. Resolve routine failures within scope and ask only for a missing choice.
- Find an existing PR for the same repository, head branch and `main` base. Reuse
  it, or execute `gh pr create --repo <owner/repo> --base main --head <branch>`
  with an explicit title and `--body-file`. Write the body to a temporary UTF-8
  file outside the ZIP, covering final behavior, version, validation and remaining
  in-game checks. Verify the remote PR head matches the prepared commit.
- Do not ask the user to commit, push, create the PR, retrieve its number or run
  a diff. Keep validation and Git inspection internal and noninteractive, using
  `git --no-pager diff` when needed. Never create an empty PR to work around a
  missing commit. Do not merge, create tags or publish in this stage.
- For an uncertain mutation result, inspect remote state before retrying so no
  duplicate PR is created. Use bounded retries for transient failures. If an
  external blocker remains, state the exact completed and pending steps rather
  than replacing the workflow with a long manual command list.

## Report the result

- Return the PR URL/number, committed version, future tag/title `v<base-version>`,
  release commit, ZIP path and concise validation results. State whether
  `docs/curseforge-listing.md` was updated or reviewed without changes; distinguish
  this local review from updating the CurseForge website. Keep simulation and
  in-game validation distinct, and describe any unresolved external blocker.
- Do not include commands for the user to run unless they explicitly request a
  manual walkthrough. In that mode, show add and commit directly; diff inspection
  is optional and uses `git --no-pager diff --cached`. Put commands on separate
  PowerShell lines without a trailing backslash for continuation.
- The completed PR is the handoff to `$per-hour-publish-release`. Invoke that
  second stage only when the user requests it. Do not promise background work
  after ending the turn or resume operations the user has told you to stop.
