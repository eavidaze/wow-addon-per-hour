# Publishing a release

## One-time setup

1. Generate a token in [CurseForge API Tokens](https://www.curseforge.com/account/api-tokens)
   using the account that manages project **486717** (Per Hour).
2. Open the repository's [Actions secrets](https://github.com/eavidaze/wow-addon-per-hour/settings/secrets/actions),
   choose **New repository secret**, name it **CF_API_KEY**, and paste the token as its value.
3. Commit and push the workflow changes, then merge `feat/forever-revive` into `main`.

## Publish

1. Test the addon in game and update `## Version` in `per-hour.toc` when needed.
2. On [New release](https://github.com/eavidaze/wow-addon-per-hour/releases/new),
   create a tag matching the addon version (for example `v1.0.0-forever`),
   select `main` as the target, add release notes, and click **Publish release**.
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
