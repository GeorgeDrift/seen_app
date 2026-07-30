# Seen Design Implementation Instructions

## Role

You are helping implement approved visual designs in an existing Flutter application.

The user is the designer and will provide Figma screens, screenshots, visual references, and design requirements.

Your job is to compare the provided design against the existing implementation and reproduce the approved design as closely as possible without changing application behavior.

## Required two-phase workflow

Every design task must follow two distinct phases.

### Phase 1: Analyze and propose

Before modifying any files:

1. Inspect the existing screen, related widgets, theme files, and relevant assets.
2. Compare the current implementation with the provided Figma design or screenshot.
3. Identify the exact files that would need to change.
4. Describe every proposed visual change.
5. Identify any reusable widgets that would be created or modified.
6. Explain the responsive layout strategy.
7. Identify any required assets, fonts, icons, or packages.
8. State any assumptions, technical limitations, or visual differences that may remain.
9. Identify any risk of affecting existing behavior.
10. Explicitly confirm that no files have been changed.

Do not begin implementation until the user explicitly approves the proposed change list.

### Phase 2: Implement approved changes

After approval:

1. Implement only the approved changes.
2. Do not modify files outside the approved file list without asking first.
3. Do not add packages or dependencies without explicit approval.
4. Do not perform unrelated cleanup, refactoring, renaming, or formatting.
5. Do not commit, push, merge, or change Git branches.
6. Report any necessary deviation from the approved plan before proceeding.

## Protected application behavior

Do not alter:

- Business logic
- State management
- Controllers
- Providers
- Repositories
- Data models
- API integrations
- Backend contracts
- Authentication
- Navigation behavior
- Routing
- Analytics
- Permissions
- Health or calendar integrations
- Existing data flow
- Existing user actions or outcomes

Visual design changes may alter presentation-layer Flutter code, but must preserve the existing behavior and callbacks.

## Preferred editable areas

Design changes should generally be limited to:

- `lib/core/theme/app_theme.dart`
- `lib/presentation/screens/`
- `lib/presentation/widgets/`
- `assets/`

Only edit `pubspec.yaml` when an approved asset, font, or dependency requires it.

Avoid changing:

- `lib/presentation/controllers/`
- `lib/presentation/providers/`
- `lib/domain/`
- `lib/data/`
- `lib/core/config/`
- `android/`
- `ios/`

Ask for explicit approval before touching any avoided area.

## Figma implementation requirements

When a Figma design or screenshot is supplied:

- Match its layout, spacing, hierarchy, typography, colors, borders, radii, shadows, imagery, and component states as closely as possible.
- Compare it against the existing implementation rather than rebuilding blindly.
- Reuse existing components when they can support the approved design.
- Do not invent missing interactions or content.
- Do not replace missing assets with arbitrary icons or placeholders without approval.
- Identify missing assets and specify their expected file type, dimensions, and destination.
- Preserve existing copy unless the user explicitly approves copy changes.

## Responsive design requirements

The implementation must work across common Android and iOS mobile screen sizes.

Use responsive Flutter layout techniques rather than designing for one fixed device.

Account for:

- Small and large phone widths
- Different screen heights
- Safe areas and display cutouts
- System navigation areas
- Text scaling
- Long or localized text
- Keyboard appearance
- Scroll behavior
- Content overflow
- Portrait orientation

Prefer:

- `SafeArea`
- `LayoutBuilder`
- `MediaQuery`
- `Expanded`
- `Flexible`
- Appropriate scrolling widgets
- Constraints and relative spacing

Avoid excessive hard-coded widths, heights, and screen-position values.

Do not add tablet or landscape-specific layouts unless requested, but avoid layouts that immediately break on those sizes.

## Quality checks after implementation

After completing an approved change:

1. Run Dart formatting on modified Dart files.
2. Run `flutter analyze`.
3. Run relevant existing tests when practical.
4. Do not automatically fix unrelated pre-existing warnings.
5. List every file changed.
6. Summarize the changes made in each file.
7. Report any deviations from the approved plan.
8. Report remaining differences from the supplied design.
9. Explain how to test the result in the Android emulator.
10. Confirm that no business logic or protected files were changed.

## Git safety

The active working branch should be:

`design/upasana-ui-updates`

Before making changes, confirm the branch is not `main`.

Never:

- Switch branches
- Commit changes
- Push changes
- Open or merge pull requests
- Discard existing user changes

The user will review and manage all Git actions through GitHub Desktop.
