# Release Guide

This repository is close to being package-ready, but there is still a difference between “works locally” and “public release”.

## Recommended Release Steps

1. Move `EditorLab` into its own repository.
2. Add a `LICENSE`.
3. Add package tests.
4. Add CI on a macOS runner.
5. Tag semantic versions.
6. Publish a stable installation path in the README.

## Why Separate The Package Repo

Right now the repository mixes:

- the reusable package
- the demo host app

That is fine for development, but public Swift packages are easier to consume when the repository root is the package root.

Consumers expect:

- `Package.swift` at the root
- `Sources/`
- `Tests/`
- `README.md`
- `LICENSE`

## Minimum Test Coverage Before Release

At a minimum, add tests for:

- heading conversion
- bullet conversion
- divider conversion
- empty bullet return behavior
- empty heading delete-backward behavior
- paste normalization

## CI

Add at least:

- package build
- demo app build if kept in the same repository

On GitHub Actions, use a macOS runner with an explicit Xcode version.

## Versioning

Use semantic version tags.

Example:

```bash
git tag 0.1.0
git push origin 0.1.0
```

Consumers can then depend on:

```swift
.package(url: "https://github.com/your-org/EditorLab.git", from: "0.1.0")
```

## Suggested First Public Version

`0.1.0` is the right first public version if:

- the API is usable
- the package is documented
- behavior is still expected to evolve

Use `1.0.0` only after the public API and core editor behavior are intentionally stable.
