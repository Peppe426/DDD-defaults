---
name: create-release
description: Create the next annotated semantic-version tag and trigger the release pipeline.
tags:
  - git
  - releases
  - powershell
  - github-actions
---

# Create a release

Use this skill when you need to create a new annotated release tag for this repository.

## Workflow

1. Get the current latest annotated release tag:

   ```powershell
   .\scripts\Get-LatestAnnotatedReleaseTag.ps1
   ```

2. Ask the user for the next version explicitly.
3. Confirm the local Git identity is configured for the tagger.
4. Create the annotated tag with the release message:

   ```powershell
   git tag -a v<version> -m "Release <version>"
   ```

5. Push the tag to origin so GitHub Actions runs the release workflow:

   ```powershell
   git push origin v<version>
   ```

## Notes

- The release workflow is triggered by annotated `vX.Y.Z` tag pushes.
- The tag annotation message should be `Release <version>`.
- The tagger identity comes from the local Git configuration.
