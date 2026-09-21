# Design QA

## Comparison Target

- Source visual truth: `C:\Users\zandr\Pictures\Screenshots\Screenshot 2026-09-19 130101.png`
- Source image pixels: 310 x 144
- Reference region: bottom-right amber circular chat launcher above a three-item bottom navigation bar
- Intended Flutter viewport: 412 x 715 logical pixels at device scale factor 1
- State: Home tab selected; launcher opens a static Chat page

## Implementation Evidence

- Implementation files: `lib/screens/home_screen.dart` and `lib/screens/chat_screen.dart`
- Browser-rendered implementation screenshot: unavailable
- Browser availability: in-app Browser runtime returned no available browser backends
- CSS size and density normalization: not performed because no browser-rendered capture was available
- Static analysis: `flutter analyze` passed with no issues
- Widget tests: `flutter test` passed (4 tests)
- Compile check: `flutter build web` passed
- Primary interactions tested: Home shows launcher; Cart hides launcher; returning Home restores launcher; tapping launcher opens Chat; launcher is not hit-testable on Chat
- Style assertions tested: amber `#FFBE24` background, black foreground, Material `Icons.chat`
- Browser console errors checked: unavailable because the in-app browser could not be acquired

## Full-view Comparison Evidence

The source crop was opened and inspected. It shows a compact amber circular launcher aligned to the right above the bottom bar. The implementation uses Flutter's circular `FloatingActionButton` at `FloatingActionButtonLocation.endFloat`, but a valid same-viewport rendered comparison could not be captured.

## Focused Region Comparison Evidence

The launcher is implemented with a circular shape, the existing amber secondary color token (`#FFBE24`), black foreground, and a filled chat icon. Widget tests verify the styling and Home-only interaction state. A rendered focused-region comparison remains unavailable.

## Findings

- [Blocked] Browser-rendered visual evidence is missing.
  - Location: Home bottom-right launcher and Chat page.
  - Evidence: browser discovery returned an empty backend list, so no implementation screenshot or console log could be captured.
  - Impact: exact position, rendered size, shadow, spacing above the bottom navigation, and final icon rasterization cannot be visually certified against the screenshot.
  - Required follow-up: open the Flutter web preview in an available in-app browser at 412 x 715, capture Home and Chat states, and compare the Home crop with the source.

## Required Fidelity Surfaces

- Fonts and typography: the launcher has no text; the static Chat page uses the project's existing Poppins theme. Rendered typography remains unverified.
- Spacing and layout rhythm: the platform `endFloat` placement matches the reference composition in code. Exact rendered margins remain unverified.
- Colors and visual tokens: the button uses the project's amber `#FFBE24` secondary token with a black icon; this is covered by a widget assertion.
- Image quality and asset fidelity: no raster asset is needed; the reference icon is matched with the Material chat icon already used by the Flutter icon system. Final rasterization remains unverified.
- Copy and content: the Chat page is intentionally static and clearly states that messaging is unavailable.

## Comparison History

- Iteration 1: source inspected; implementation added; widget test found that Flutter retains the departing FAB during its transition, so visibility assertions were corrected to test the hit-testable state after both transition frames.
- Iteration 2: static analysis, all widget tests, and the web build passed. Browser capture remained blocked because no browser backend was available.

## Implementation Checklist

- [x] Add the amber circular chat launcher at the bottom-right of Home.
- [x] Hide the launcher on Cart and Account tabs.
- [x] Open a static, non-functional Chat page when tapped.
- [x] Verify button color, icon, visibility behavior, and navigation with widget tests.
- [x] Pass static analysis and the web build.
- [ ] Capture Home and Chat in an available browser and check console health.

final result: blocked
