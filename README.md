# Basil

Basil is a macOS SwiftUI editor experiment built with AppKit-backed rich text editing primitives.

## Current behavior

- Renders a custom editor surface inside a SwiftUI app
- Converts Markdown-style triggers into styled blocks
- Supports headings with `#` through `####`
- Supports list items with `- `
- Converts `---` into a visual divider block

## Project layout

- `Basil/`: app source and assets
- `Basil.xcodeproj/`: Xcode project

## Requirements

- macOS
- Xcode with the full app installed

## Run locally

1. Open `Basil.xcodeproj` in Xcode.
2. Select the `Basil` scheme.
3. Build and run the app.
