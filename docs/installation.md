# Installation

This package is macOS-only and depends on AppKit.

## Option 1: Add As A Local Package

Use this while developing the package and the host app side by side.

1. Put the `EditorLab` folder somewhere accessible on disk.
2. Open your host app in Xcode.
3. Choose `File` -> `Add Package Dependencies...`
4. Click `Add Local...`
5. Select the `EditorLab` directory
6. Link the `EditorLab` product to your app target

Then import it in code:

```swift
import EditorLab
```

## Option 2: Add From GitHub

Once `EditorLab` lives in its own GitHub repository:

1. Open your host app in Xcode.
2. Choose `File` -> `Add Package Dependencies...`
3. Paste the GitHub repository URL
4. Choose a version rule
5. Add the `EditorLab` library product to your app target

## Package.swift Integration

If your app is package-managed:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/EditorLab.git", from: "0.1.0")
]
```

Then add the product dependency:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "EditorLab", package: "EditorLab")
    ]
)
```

## Minimum Requirements

- macOS 13+
- Swift 6
- Xcode with a compatible Swift toolchain

## Recommended Repository Layout

For public reuse, the cleanest structure is:

```text
EditorLab/
  Package.swift
  Sources/
  Tests/
  README.md
  LICENSE
```

Right now this repository contains both the package and the demo host app. That is fine for development, but public consumers usually expect the package to live in its own repository.
