---
name: per-hour-publish-release
description: Automatically merge a prepared Per Hour PR into main, publish its GitHub Release and follow Release Addon through the CurseForge and GitHub uploads. Use after the version bump and notes are committed; use per-hour-prepare-release for candidate preparation and PR creation.
---

# Per Hour PR finalization and publication

Execute the workflow from a prepared PR through merge into `main`, GitHub
Release publication and verification of Release Addon. Communicate in Portuguese.
The user has authorized normal invocations to perform this stage automatically;
do not return a command list or ask for routine confirmation instead of executing.
Ask only when a material doubt or ambiguity cannot be resolved from context.
Discussing or editing the skill does not authorize publishing a release, and a
request to stop remains effective until the user requests resumption.

## Establish the PR and release candidate

- Read `AGENTS.md`, `docs/releasing.md`, `.github/workflows/release.yml` and
  `pkgmeta.yaml`. Inspect the local branch, working tree and index without
  changing the user's branch, files or staging choices. Never execute a commit.
- Prefer a supplied PR URL/number. Otherwise identify the unique PR for the
  current branch targeting `main` in the configured repository. Ask only if the
  intended PR cannot be identified unambiguously. Inspect the head repository,
  base, head SHA, diff, state, mergeability, checks and review requirements.
- Read `per-hour.toc` and `docs/releases/<toc-version>.md` from the PR's committed
  head, not from an uncommitted local candidate. Respect the prepared version
  and any explicit requested version. Do not apply another bump or silently
  change the version, Interface, release notes or PR scope during publication.
  Missing release files or mismatches must be resolved before publication.
- Verify that notes reflect the actual release diff and distinguish simulation
  from in-game validation. Reuse validation evidence only when it applies to
  the exact candidate contents; when missing or invalidated, obtain the required
  Lua 5.1 and package checks using an isolated checkout or archive so the user's
  working tree stays intact. A successful workflow later is separate evidence.
- Derive both tag and title as `v<base-version>`, stripping only the trailing
  `-forever` from the committed TOC version. Example: `1.2.0-forever` maps to
  `v1.2.0`. Keep the committed notes filename. The workflow's `-g forever`
  appends `-forever` to the ZIP filename and upload label when absent; it does
  not rename the GitHub release or tag.
- Check authentication and permissions in the real execution environment and
  reuse the valid session. A sandbox's token failure does not prove the host is
  unauthenticated; verify with a read-only host check when available. Do not add
  login steps routinely or expose credentials. Keep review and validation internal,
  and handle routine failures without handing operational steps back to the user.

## Merge and verify main

- The user's "approve the PR" means merge, not a formal approving review. Do
  not add self-approval commands. Honor required reviews and checks, and never
  use `--admin` to bypass them or delete branches unless explicitly requested.
- Respect the repository's merge strategy; otherwise prefer `--merge` when
  allowed to preserve separate commits. For an open PR, execute
  `gh pr merge <pr> --repo <owner/repo> <strategy> --match-head-commit <reviewed-sha>`
  using the actual reviewed head SHA. If the head changes, inspect and validate
  the new diff before proceeding. Do not silently fix merge conflicts here.
- If already merged, skip merging and continue from its actual merge commit.
  If closed without merging, report it instead of reopening or publishing it.
  Queued/automatic merge is not completion: wait for actual `MERGED` state
  before continuing. Pending checks or required reviews remain pending work.
- Fetch `main` from the selected remote. Obtain the actual merged SHA using
  `gh pr view --json state,mergeCommit`; confirm it is contained in remote main
  with `git merge-base --is-ancestor`. Verify TOC version, Interface and notes at
  that SHA, including any differences introduced during the merge. Never use a
  stale local main, the feature-branch head, or whatever main points to later.
- Extract the reviewed notes from the verified merged commit into a temporary
  UTF-8 file for `--notes-file`, or verify an existing local file matches that
  committed file. Do not publish notes from uncommitted working-tree changes.

## Publish and verify the workflow

- Inspect both the tag and GitHub Release before creating anything. If the tag
  already exists, resolve it to its commit and require the verified merged SHA;
  never move it. If the version is already published with matching contents,
  report the existing release and inspect its workflow instead of publishing
  again. A conflicting tag/release or different contents require resolution.
- Execute `gh release create v<base-version> --repo <owner/repo>
  --target <verified-merged-sha> --title v<base-version> --notes-file <notes-file>`
  with concrete values. For a new tag, this creates the tag and publishes the
  release; no separate `git tag` or tag push is needed. For an existing compatible
  tag, use `--verify-tag`. If a matching draft exists, reuse and publish it with
  the verified title and notes rather than create a duplicate.
- Invocation authorizes merge, tag creation through the release operation,
  publication and workflow monitoring after these checks. Do not ask for repeated
  confirmation or require the user to run these operations. Stop dependent actions
  on failures, mismatched values or a changed head; inspect and resolve routine
  issues within scope. Ask only when a missing choice affects what to publish.
- If a merge response times out or reports "already in progress", inspect PR and
  main before retrying. Treat it as an uncertain server result, not proof of a
  permission block or completed merge. Use bounded polling and retries; check the
  official service status when failures persist. Do not send repeated mutations
  while an earlier merge is still in progress or bypass the PR by pushing main.
  If the service remains blocked, report the actual state without claiming success
  or asking the user to perform the same failing operation manually.
- Publishing the GitHub Release triggers `release: published` in **Release
  Addon**. A tag push or draft alone does not trigger it. Let that workflow run
  the Lua checks, package, upload to CurseForge and attach the GitHub ZIP; do not
  manually upload the validation ZIP or create a second CurseForge upload.
- Inspect the published release and locate the run for this release/tag and
  merged SHA. Follow it to completion within the current task with bounded polling
  or `gh run watch`; do not ask the user to monitor it. Keep progress updates brief
  and distinguish actual changes from unchanged polling results.
  If no run appears after a bounded check, report the missing trigger rather
  than republish. Do not retry publication or rerun an upload job automatically
  after a failure, because an earlier upload may already have succeeded.
- Verify the expected release ZIP asset and workflow conclusion. Distinguish
  release publication, workflow success/failure and CurseForge processing or
  approval; a successful upload does not prove public CurseForge availability
  or actual in-game validation. Do not modify secrets, CI or external listing
  fields as part of routine publication.

## Report

- Identify the PR, merge status, verified commit, TOC version, tag/title,
  release URL, workflow URL/status, ZIP asset and any optional CurseForge
  listing differences or in-game checks. Do not claim completion from a command
  that was only prepared or a run that is still pending.
- Keep the final response focused on completed outcomes, links and any genuine
  external blocker. Supply a manual command sequence only when the user explicitly
  requests it. Do not introduce another bump or unrelated commits.
- Do not resume a canceled operation merely because this skill is being edited,
  and do not promise background monitoring after ending the turn.
