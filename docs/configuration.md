# Configuration Guide

`EditorLab` is designed so the host app controls inner editor styling and selected editing behaviors without needing access to the AppKit internals.

## Configuration Entry Point

The root type is `MarkdownEditorConfiguration`.

```swift
let configuration = MarkdownEditorConfiguration(
    theme: .init(),
    behavior: .init()
)
```

It has two parts:

- `MarkdownEditorTheme`
- `MarkdownEditorBehavior`

## Theme

`MarkdownEditorTheme` controls the visual appearance inside the editor surface.

### Text styles

Use `MarkdownEditorTextStyle` for:

- `bodyStyle`
- `heading1Style`
- `heading2Style`
- `heading3Style`
- `heading4Style`
- `bulletStyle`

Each text style includes:

- `font`
- `textColor`
- `lineSpacing`
- `paragraphSpacingBefore`
- `paragraphSpacing`

Example:

```swift
let body = MarkdownEditorTextStyle(
    font: .systemFont(ofSize: 17, weight: .regular),
    textColor: .labelColor,
    lineSpacing: 5,
    paragraphSpacing: 10
)
```

### Other theme fields

`MarkdownEditorTheme` also controls:

- `editorBackgroundColor`
- `contentInset`
- `bulletIndent`
- `bulletContentIndent`
- `dividerColor`
- `dividerThickness`
- `dividerHorizontalInset`
- `dividerLineHeight`
- `dividerSpacingBefore`
- `dividerSpacing`

## Behavior

`MarkdownEditorBehavior` controls which editing rules are active.

Available fields:

- `enabledHeadingLevels`
- `enablesBullets`
- `enablesDividers`
- `exitsBulletOnReturnWhenEmpty`
- `convertsEmptyHeadingOnDeleteBackward`

Example:

```swift
let behavior = MarkdownEditorBehavior(
    enabledHeadingLevels: [.h1, .h2, .h3],
    enablesBullets: true,
    enablesDividers: true,
    exitsBulletOnReturnWhenEmpty: true,
    convertsEmptyHeadingOnDeleteBackward: true
)
```

## Recommended Styling Boundary

Keep this inside the package configuration:

- typography
- text colors
- editor background color
- content inset
- bullet alignment
- divider styling

Keep this in the host app:

- gradients
- textured backgrounds
- shadows
- rounded outer cards
- window-level layout and chrome

That separation keeps the package focused on editing and inner presentation rather than app-wide design.
