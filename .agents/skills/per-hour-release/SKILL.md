---
name: per-hour-release
description: Execute a Per Hour release end to end for WoW Forever by combining preparation and publication, from version selection and validation through PR merge, GitHub Release and upload workflow verification. Use when the user requests both stages; use the individual skills for preparation or publication alone.
---

# Per Hour end-to-end release

Execute [preparation](../per-hour-prepare-release/SKILL.md) followed by
[publication](../per-hour-publish-release/SKILL.md) in the same task. Read both
skills and `AGENTS.md` before starting; follow their detailed procedures rather
than duplicating or replacing them. Communicate in Portuguese.

Invoking this workflow authorizes both stages: the preparation commit, push and
PR creation, then merge, tag creation through GitHub Release publication and
workflow monitoring. The preparation skill's PR handoff is an intermediate
checkpoint here; continue automatically without asking the user to invoke the
publication skill. Ask only about material doubts or ambiguities that cannot be
resolved from the repository and session context. Discussing, creating or editing
these skills does not run a release or resume a stopped operation.

## Prepare or reuse the candidate

- Honor the requested version, branch and scope. Run the preparation skill when
  a candidate still needs preparation. Keep automatic commits confined to that
  stage's release changes and preserve unrelated files and staging choices.
- Reuse an already prepared version, release commit and matching PR. If the user
  supplies an already prepared PR, proceed with the publication skill's candidate
  checks instead of creating a second bump or PR. Resolve ambiguous candidates
  before any mutation. Do not select a fresh version merely because an earlier
  attempt already merged or published the intended release.
- Carry forward the repository, PR URL/number, reviewed head SHA, TOC version,
  notes path, tag/title and validation evidence. Review the CurseForge listing
  during preparation even when reusing a release commit. A brief progress update
  can report the PR; do not end the task at that handoff.
- Continue to publication only when the candidate and required Lua 5.1 and ZIP
  validation are complete and successful. Missing or failed validation remains
  pending work; obtain evidence for the exact committed contents using the
  publication skill's isolated validation procedure when needed. Do not treat
  simulation results as in-game validation.

## Publish and follow through

- Execute the publication skill against that same PR and reviewed candidate.
  Recheck its head and required checks before merge, and use the verified actual
  merge commit for the release. Never publish after a failed preparation, push
  or PR operation, or while merge is only queued.
- Preserve the publication skill's handling of existing merges, tags, drafts and
  releases. Inspect remote state before retrying an uncertain mutation. Never
  move a tag, bypass required reviews/checks, force-push, or repeat an upload
  automatically after a workflow failure.
- Follow Release Addon to its conclusion within the task and verify the GitHub
  ZIP asset. Respect bounded retries and polling; if an external blocker remains,
  report the completed and pending stages without claiming completion. Honor a
  user stop immediately and do not promise monitoring after ending the turn.

## Report the outcome

Return one concise final result covering the TOC version, PR and merge, verified
commit, tag/title, release URL, workflow URL/conclusion and ZIP asset. State the
local CurseForge listing review result and any remaining in-game validation or
external blocker. Distinguish a successful upload from CurseForge public
availability. Do not replace execution with a manual command list unless asked.
