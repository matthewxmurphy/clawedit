# GitHub release lookup contract

Author/developer: Matthew X Murphy, https://MatthewxMurphy.com. Product attribution:
https://builtnotbegged.com. Existing MIT LICENSE and upstream notices are retained.

`GitHubReleaseChecker` reads GitHub's latest-release endpoint with an injectable
URLSession. It accepts only HTTP200 with a nonempty tag and an HTTPS release URL
under the requested GitHub repository. Supplied publication dates must parse.
Transport failures, non-HTTP replies, other statuses and malformed/incomplete JSON
throw errors; no fallback manufactures a successful unknown release.

The view model displays failure text and clears an earlier release link on error.
It keeps the existing in-flight button guard. The lookup is informational: it
neither downloads nor installs code, proves version compatibility, signs an app
nor creates a GitHub release. API authentication, channel selection and package
verification are outside this scoped repair. See the
[official latest-release API](https://docs.github.com/en/rest/releases/releases#get-the-latest-release).

## Offline native contract tests

From this repository with Swift6 and the macOS SDK:

```sh
swiftc -swift-version 6 -parse-as-library \
  Sources/ClawEdit/ReleaseChecking.swift \
  Sources/ClawEdit/CompanionModels.swift \
  Sources/ClawEdit/CompanionServices.swift \
  Tests/ReleaseCheckerContract.swift -o /tmp/clawedit-release-contract
/tmp/clawedit-release-contract
```

The real checker and view-model source compile together. The executable checks a
realistically shaped release, HTTP201/204/403/404/429/500, malformed JSON, error
objects, empty tags, invalid URLs/dates, non-HTTP replies and invalid repository
input. An ephemeral session with fixture URLProtocol handles every request; no
GitHub request, token, user configuration read or app-state write occurs.
UI failure-link clearing is manually reviewed in source; no rendered UI check or
live GitHub service result is claimed by these fixtures.

The baseline full `swift build` was attempted in the review environment and fails
on the existing SwiftUI `StateMacro` SDK plugin, before this change. Standalone
Foundation/Combine service tests avoid that unavailable GUI plugin. A successful
full app build, macOS14 compatibility run, unsigned bundle packaging, signing,
notarization and distribution remain separate verification states.

## Maintenance and adoption

Shared SOP and the repository README/license were reviewed. Source attribution,
regression checks, contract notes, exact-index scanning and scoped Git review are
part of this fix. No existing release version, license text or owner is changed.
Portable checker/engineering.json integration and the complete documentation set
remain adoption gaps; no CI workflow or enforced branch checks existed here.
Rollback is a scoped source revert that preserves later work. No deployment or
public release follows automatically from a source commit.
