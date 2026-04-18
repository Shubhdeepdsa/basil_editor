# Behavior Reference

This package currently implements a compact set of live markdown-like block transforms.

## Supported Triggers

At the start of a paragraph:

- `# ` -> Heading 1
- `## ` -> Heading 2
- `### ` -> Heading 3
- `#### ` -> Heading 4
- `- ` -> Bullet

On a paragraph by itself:

- `---` -> Divider

## How Conversion Works

The editor does not re-parse the entire document on every keystroke.

Instead it:

1. inspects the current paragraph
2. checks whether it matches a known trigger
3. mutates only that paragraph
4. reapplies attributes for the target block type
5. restores typing position

## Selection Behavior

The implementation is designed to:

- remove trigger text without visibly leaving it behind
- keep the caret in a reasonable typing position
- avoid broad selection jumps during programmatic edits

## Paste Behavior

On paste, the editor normalizes the document content so pasted markdown-like text can be converted and restyled into the editor’s theme.

Current goals of paste normalization:

- convert pasted heading triggers into heading blocks
- convert pasted `- ` lines into bullet paragraphs
- convert pasted `---` lines into dividers
- replace pasted fonts and colors with the configured editor theme

## Special Cases

### Empty bullet + Return

If bullet content is empty and `exitsBulletOnReturnWhenEmpty` is enabled:

- the bullet paragraph is removed
- the editor exits back to a normal paragraph

### Empty heading + Delete backward

If the caret is in an empty heading and `convertsEmptyHeadingOnDeleteBackward` is enabled:

- the heading becomes a normal paragraph

### Divider return behavior

Pressing `Return` on a divider inserts a normal paragraph after it.

## Current Limitations

- no markdown serializer
- no markdown parser API for loading raw markdown as a first-class document format
- no inline formatting model
- no ordered list engine
- no nested list model
- no document schema exposed as public API
