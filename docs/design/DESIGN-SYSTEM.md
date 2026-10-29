# Opal design system

Opal keeps Apple's look. Tokens live in `Modules/OpalKit/Sources/OpalDesign` and cover only what the system does not: spacing, radii, opacities, a few custom fills, Editor and window metrics, and motion. A view in `App/Opal/Presentation` never writes a literal colour, spacing, radius, size or animation. `PresentationTokenCheckTests` (Swift Testing, runs with the suite) fails if one appears; `LiteralScannerTests` shows what it flags and what it allows.

Start from `docs/design-brief.md` and the `mac-design` rules. This page says which token to use when.

## Accent

- The accent is the system accent colour. Use `AppColor.accent` (SwiftUI) or `AppKitColor.accent` (AppKit). Opal has no colour picker and no brand colour.
- Text or a symbol on an accent fill uses `AppColor.onAccent`, never a fixed white.
- Selected rows in the Quick Switcher, Command Palette, Template picker and Link suggestions: accent fill with `AppRadius.row`, text `AppColor.onAccent`, secondary text at `AppOpacity.emphasized` or `AppOpacity.subdued`.
- Never redefine a semantic colour (`.separator`, `.secondary`, label colours). Use them as they are, or through an `AppKitColor` role.

## Colour roles (`AppColor`, `AppKitColor`)

| Need | Token |
| --- | --- |
| Editor and Reading view background | `AppColor.editorBackground`, `AppKitColor.editorBackground` |
| Editor text, secondary text, marks | `AppKitColor.text`, `.secondaryText`, `.quietText` |
| Inline code and code block fill | `AppColor.codeFill`, `AppKitColor.codeFill` |
| Quote bar | `AppKitColor.divider` |
| Callout fill | `AppColor.calloutFill`, `AppKitColor.calloutFill` |
| `#tag` chip | `AppColor.tagFill`, `AppKitColor.tagFill` |
| Link to a Note that does not exist | `AppColor.unresolvedLink`, `AppKitColor.unresolvedLink` |
| `==highlight==` | `AppColor.highlight`, `AppKitColor.highlight` |
| Matching words in Search results | `AppColor.searchMatch` |
| Error such as "Not Saved" | `AppColor.failure` |
| Code token colours in Reading view | `AppColor.codeKeyword`, `.codeString`, `.codeNumber`, `.codeComment` |

Add a role when a second view needs the same fill. Do not add one for a single use of a system colour.

## Spacing (`AppSpacing`)

`tiny 2` (stacked lines of text), `xsmall 4` (inside a row, around a list), `compact 6` (row padding, table cells), `small 8` (default gap and padding), `medium 10` (block padding), `regular 16` (sections, sheets), `large 24` (Welcome, Move sheet).

- `0` is fine (`VStack(spacing: 0)`). Any other number is a token.
- Never do arithmetic on a token (`AppSpacing.xsmall + 2`). Add a step instead.
- Text inside the Editor uses `EditorMetrics.textInset`, the same in the Properties form and Reading view, so everything lines up with the text.

## Radii (`AppRadius`)

`row 6` for row selection, chips, code blocks, tables, callouts and tabs. `panel 8` for floating panels (Link suggestions). Inner radius = outer radius minus inset.

## Opacity (`AppOpacity`)

`emphasized 0.8` and `subdued 0.7` for secondary text inside a selected row. `disabled 0.45` for a command that cannot run. `unresolved`, `highlight`, `searchMatch`, `tag` and `callout` feed the fill roles above; use the role, not the number.

## Metrics (`EditorMetrics`)

Editor font size, text inset, heading and code scales, block bar and indent, line widths, sidebar, inspector, pane, window, switcher and Welcome sizes, Properties column widths, tab width, PDF embed height, Settings width, Link suggestion size.

- A fixed width or height in a view comes from here. `.infinity` and `0` are fine.
- A new screen with a fixed size adds its constants here, not in a per-view `Constants`.

## Motion (`AppMotion`)

`quick 120 ms` for presses and small changes, `standard 200 ms` for panels and selection moving, `dismissDelay 100 ms` for letting a panel close before its command runs.

- Every animation uses an `AppMotion` duration. Never `.easeInOut`, `.spring` or `duration: 0.2` in a view.
- Search results, switchers and the Command Palette do not animate. Speed wins.
- Never animate a view's first layout. Respect Reduce Motion.

## Controls

- Style controls with `ButtonStyle` and `ToggleStyle`; never rebuild one from shapes. It loses the keyboard, focus and VoiceOver.
- One primary button (`.borderedProminent`) per sheet or page.
- Use system materials (`.bar`, `.regularMaterial`) for chrome. A custom surface in its neutral state is translucent.

## Check

```
cd Modules/OpalKit && xcrun swift test --filter OpalDesignTests
```

The scan skips comments and everything from the first `#if DEBUG` or `#Preview` in a file. It allows `0`, system semantic colours (`.secondary`, `.separator`, `Color.accentColor`, `NSColor.textColor`), `Task.sleep(for: .seconds(...))` in snapshot launch hooks, and integer constants such as a nesting depth.

## Screens

Light and dark snapshots after the M6-02 refactor are in `docs/screens/opal-m6-02-*.png`.
