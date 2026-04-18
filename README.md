# EditorLab

`EditorLab` is a native macOS WYSIWYG markdown-trigger editor built on AppKit.

It is designed for apps that want Typora-style live block conversion without embedding a web editor. The package wraps an `NSTextView` editing engine and exposes a small SwiftUI-first API for host apps.

## Status

This repository currently contains:

- `EditorLab/`: the reusable Swift Package
- `Basil/`: a small macOS host app used as the demo and integration surface

The package is usable now, but it is still early-stage and intentionally focused. It is not a full markdown editor and it is not a note-taking app framework.

## Features

- Native macOS editor built on `NSTextView`
- SwiftUI embedding API
- Live markdown-like trigger conversion
- Attributed text state surface
- Configurable typography, spacing, colors, bullets, and divider appearance
- Paste normalization so pasted markdown-like content is restyled into the editor’s visual system

## Supported Triggers

- `# ` at the start of a line -> Heading 1
- `## ` at the start of a line -> Heading 2
- `### ` at the start of a line -> Heading 3
- `#### ` at the start of a line -> Heading 4
- `- ` at the start of a line -> Bullet item
- `---` on a line by itself -> Divider

## What It Does Not Do

Current non-goals:

- markdown import/export API
- bold / italic / inline marks
- ordered lists
- checklists
- code blocks
- tables
- file saving
- syncing
- multi-document app scaffolding
- iOS support

## Requirements

- macOS 13 or later
- Xcode with the full app installed
- Swift 6 toolchain compatible with your Xcode version

## Installation

### Local package

If the package lives next to your app on disk:

1. Open your app project in Xcode.
2. Choose `File` -> `Add Package Dependencies...`
3. Click `Add Local...`
4. Select the `EditorLab` folder
5. Add the `EditorLab` package product to your app target

### GitHub package

Once the package lives in its own GitHub repository, another app can add it from Xcode using the repository URL.

Package dependency form:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/EditorLab.git", from: "0.1.0")
]
```

Target dependency form:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "EditorLab", package: "EditorLab")
        ]
    )
]
```

## Quick Start

```swift
import EditorLab
import SwiftUI

struct ContentView: View {
    @StateObject private var editorState = MarkdownEditorState(
        text: """
        # Title

        - First item
        - Second item
        """
    )

    var body: some View {
        MarkdownEditorView(
            state: editorState,
            configuration: .default
        )
    }
}
```

## Public API

The current public API is intentionally small.

### `MarkdownEditorView`

The SwiftUI entry point for rendering the editor.

```swift
MarkdownEditorView(
    state: editorState,
    configuration: configuration
)
```

### `MarkdownEditorState`

Observable editor state that currently exposes attributed text.

```swift
@StateObject private var editorState = MarkdownEditorState()
```

Available surfaces:

- `attributedText`
- `plainText`

### `MarkdownEditorConfiguration`

The root configuration object. This is split into:

- `MarkdownEditorTheme`
- `MarkdownEditorBehavior`

## Theming

The package is designed so the host app controls inner editor styling.

Theme configuration supports:

- body text font and color
- heading fonts and sizes
- bullet font and spacing
- editor background color
- content inset
- bullet indentation
- divider color, thickness, and spacing

Example:

```swift
let configuration = MarkdownEditorConfiguration(
    theme: MarkdownEditorTheme(
        bodyStyle: MarkdownEditorTextStyle(
            font: .systemFont(ofSize: 17),
            textColor: .labelColor,
            lineSpacing: 5,
            paragraphSpacing: 10
        ),
        heading1Style: MarkdownEditorTextStyle(
            font: .systemFont(ofSize: 30, weight: .bold),
            textColor: .labelColor,
            lineSpacing: 3,
            paragraphSpacingBefore: 18,
            paragraphSpacing: 14
        ),
        editorBackgroundColor: .textBackgroundColor,
        contentInset: NSSize(width: 28, height: 26),
        bulletIndent: 18,
        bulletContentIndent: 38,
        dividerColor: .separatorColor
    )
)
```

Outer presentation such as gradients, textures, cards, shadows, or full-window backgrounds should stay in the host app.

## Behavior Configuration

`MarkdownEditorBehavior` lets the host app control which live transforms are enabled.

Current options:

- `enabledHeadingLevels`
- `enablesBullets`
- `enablesDividers`
- `exitsBulletOnReturnWhenEmpty`
- `convertsEmptyHeadingOnDeleteBackward`

Example:

```swift
let configuration = MarkdownEditorConfiguration(
    behavior: MarkdownEditorBehavior(
        enabledHeadingLevels: [.h1, .h2],
        enablesBullets: true,
        enablesDividers: false
    )
)
```

## Editing Behavior

Important current behavior:

- trigger conversion is paragraph-local, not full-document on every keystroke
- raw trigger text is removed after conversion
- pasted markdown-like content is normalized and restyled
- pressing `Return` on an empty bullet exits the bullet paragraph
- pressing `Delete` backward on an empty heading converts it back to a normal paragraph

## Architecture

`EditorLab` is not built on `TextEditor`.

The implementation is based on:

- `AppKit`
- `NSTextView`
- `NSTextStorage`
- `NSAttributedString`
- delegate and mutation-driven paragraph transforms

The rough split is:

- public SwiftUI wrapper and config/state types
- internal AppKit editor engine
- internal block styling and mutation logic

## Project Layout

```text
EditorLab/
  Package.swift
  Sources/
    EditorLab/
      Public/
      Internal/

Basil/
  Demo host app
```

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
