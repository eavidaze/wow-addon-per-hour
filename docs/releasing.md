# Publishing a release

## One-time setup

1. Generate a token in [CurseForge API Tokens](https://www.curseforge.com/account/api-tokens)
   using the account that manages project **486717** (Per Hour).
2. Open the repository's [Actions secrets](https://github.com/eavidaze/wow-addon-per-hour/settings/secrets/actions),
   choose **New repository secret**, name it **CF_API_KEY**, and paste the token as its value.

## Prepare a version

1. Review the changes since the previous published Forever release. Update
   `## Version` in `per-hour.toc` if a new version has not already been prepared.
   Keep `## Interface` unchanged unless the target client changes.
2. Update the usage instructions in `README.md`, the text in
   [curseforge-listing.md](curseforge-listing.md), and the release notes in
   `docs/releases/<version>.md` to match the new behavior.
3. Run `lua tests/forever.lua` with Lua 5.1 and generate the local package with
   `.\scripts\package.ps1`. Check the ZIP version, folder layout and load references.
   Validate the addon in game; simulation results alone do not establish gameplay compatibility.
4. Review and commit the prepared changes, then merge the release branch into `main`.
   Merge only the version and behavior intended for this release.

## Publish

1. Confirm that `main` contains the prepared version and reviewed release notes.
   The next prepared version is `1.1.1-forever`; its notes are in
   [releases/1.1.1-forever.md](releases/1.1.1-forever.md).
2. On [New release](https://github.com/eavidaze/wow-addon-per-hour/releases/new),
   create a tag matching the addon version (`v1.1.1-forever` for this version),
   select `main` as the target, copy the user-facing release notes, and click **Publish release**.
3. Follow **Release Addon** in [Actions](https://github.com/eavidaze/wow-addon-per-hour/actions).
   It runs the Lua checks, packages the addon, uploads it to CurseForge,
   and attaches the ZIP to the GitHub release.

Only a published GitHub Release triggers this workflow; a normal commit, branch
push, draft release or tag push alone does not publish the addon. CurseForge may
need to process or approve the uploaded file before making it available.

The GitHub token is provided automatically. Only `CF_API_KEY` needs manual setup.
Use this workflow as the publishing path; if an older CurseForge packaging webhook
is active, disable it before publishing to avoid duplicate uploads.

The project name, summary and description live in [curseforge-listing.md](curseforge-listing.md).
Copy each section into the corresponding CurseForge field when updating the listing;
the release workflow does not synchronize these fields.

Reference: [WoW Packager](https://github.com/BigWigsMods/packager).
