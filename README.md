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

Package source and documentation live at:

- https://github.com/Shubhdeepdsa/EditorLab

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
