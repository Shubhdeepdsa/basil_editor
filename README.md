# Basil

`Basil` is the demo macOS app for `EditorLab`.

This repository is no longer the canonical package home for the editor. The reusable Swift package now lives in a separate repository checkout named `EditorLab`.

## What This Repo Is

- a demo/consumer app for the `EditorLab` package
- an Xcode project that exercises the editor inside a real macOS host app

It is not the package distribution source.

## Package Location

The `Basil.xcodeproj` local package reference now expects the package repository to exist as a sibling checkout:

```text
../Basil
../EditorLab
```

In other words:

- this repo: `Basil`
- package repo: `EditorLab`

## Run Locally

1. Check out the `EditorLab` package repository next to this repository.
2. Open `Basil.xcodeproj` in Xcode.
3. Build and run the `Basil` scheme.

## Editor Package

`EditorLab` provides:

- native macOS WYSIWYG markdown-trigger editing
- AppKit-backed `NSTextView` behavior
- SwiftUI embedding API
- package tests and package CI

Install and package documentation now belong in the `EditorLab` repository.

## Example Host Styling

The host app can wrap the editor in its own presentation:

```swift
ZStack {
    Color(nsColor: .windowBackgroundColor).ignoresSafeArea()

    MarkdownEditorView(
        state: editorState,
        configuration: configuration
    )
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
    )
    .padding(24)
}
```

## Release Notes For Consumers

Before calling this a stable public package, the next release-quality steps are:

1. move `EditorLab` into its own repository
2. add semantic version tags
3. add CI build validation on a macOS runner
4. add package-level tests for paragraph transforms
5. document versioned release notes

## Documentation

- [Installation guide](docs/installation.md)
- [Configuration guide](docs/configuration.md)
- [Behavior reference](docs/behavior.md)
- [Release guide](docs/releasing.md)

## License

No license file is included yet. Add one before publishing the package publicly.
