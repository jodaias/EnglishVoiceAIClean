# Next Steps

This file is the current action plan for evolving the app as a high-quality English learning product.

## Current Priority Roadmap

1. Stabilize speaking session behavior

- Tune `listenFor` and `pauseFor` using real family testing feedback.
- Validate inactivity pause timing so it feels natural.

2. Save local session history

- Persist: practice focus, duration, user turns, and end-of-session feedback.
- Add a simple "Previous Sessions" view.

3. Add progress screen

- Show weekly metrics: practiced minutes, active days, most used focus areas.
- Highlight consistency and streak indicators.

4. Improve pedagogical report quality

- Add simple level estimate (for example: Beginner / Intermediate).
- Include 3 recommended short sentences for repetition practice.

5. Add daily challenge

- One daily micro-goal (5 to 8 minutes) with a specific topic.
- Mark completion and encourage consistency.

6. Run a 7-day family test cycle

- Test with 5 to 10 people.
- Collect quick feedback: what worked, what confused, what to improve.

7. UX polish

- Improve readability and spacing in chat and feedback panels.
- Refine status messages to sound natural and supportive.

8. Prepare monetization-ready architecture (without enabling payment yet)

- Add feature flags for premium capabilities.
- Keep payment flow isolated for easy activation later.

## Value-First Execution Plan (2026-03-07)

This section prioritizes what most improves real user experience and perceived learning value in the next implementation cycles.

### Sprint 1 - Immediate User Value (do first)

1. Conversation reliability and confidence

- Add integration tests for `PracticeHubController` + Hive load/refresh paths.
- Add targeted tests for STT concurrency/retry behavior in web flows.
- Track lightweight STT start-failure counter to validate stability improvements.

Why first

- If conversation starts/resumes fail or feel unstable, users drop quickly.
- Reliability is the strongest short-term retention lever.

2. Full bilingual UX parity (`en-US` and `pt-BR`)

- Expand localization coverage to remaining voice-chat status and helper messages.
- Add tests for app language toggle persistence across restarts.
- Keep response language aligned to detected/user-selected mode.

Why first

- Language inconsistency breaks trust immediately, especially in learning contexts.
- Fixing this directly improves usability for all target users.

3. Clear session continuity feedback

- Add explicit "listening resumed" hint behavior during resume grace period.
- Validate inactivity pause messaging tone in both languages.

Why first

- Users need to understand current assistant state without guessing.
- Better state feedback reduces frustration and accidental drop-offs.

### Sprint 2 - Learning Motivation and Retention

1. Progress visibility that feels useful

- Improve weekly progress with consistency/streak emphasis.
- Add optional filters/search in `Previous Sessions` for frequent users.

2. Better pedagogical outcomes per session

- Improve end-of-session report quality with level estimate + repetition sentences.
- Add tests for feedback generation success/failure paths.

3. Daily challenge stickiness

- Keep daily micro-goal flow prominent and easy to complete.
- Persist and expose completion history as simple motivation signal.

### Sprint 3 - Product Scalability and UX Maturity

1. Settings and preferences hardening

- Persist remaining session settings currently held only in UI state.
- Ensure settings entry points are consistent across dashboard/session pages.

2. Responsive quality guardrails

- Add widget/golden coverage for desktop breakpoints (1024/1280/1600+).
- Keep `ResponsiveContentShell` profile behavior protected by tests.

3. Monetization-ready, still disabled

- Continue isolating premium capabilities behind feature flags.
- Avoid coupling payment concerns with core learning flow.

### Success Criteria for This Plan

- Conversation can be resumed and sustained with low failure rates in real-device tests.
- User-visible text and state feedback stay consistent in `en-US` and `pt-BR`.
- Users can clearly see progress and complete daily challenge with minimal friction.
- Test coverage expands around reliability and persistence-critical paths.

## Update Rule

At the end of each implementation cycle, update this file with:

- Completed items
- New priorities discovered during testing
- Any blockers and decisions taken

## Implementation Cycle Update (2026-03-07)

Completed items

- Priority 1 partially completed: speaking session timing is now configurable in code (`listenFor`, `pauseFor`, loop delay, and inactivity threshold), enabling safer tuning from real-device feedback without changing core flow logic.
- Added automated tests for controller behavior covering:
  - auto-language STT fallback (`en_US` to `pt_BR`)
  - inactivity auto-pause behavior
  - in-session command handling (`slow down`) without unnecessary AI calls

New priorities discovered during testing

- Add a lightweight app-level configuration source for session timing values (instead of constructor-only values) to support easier product experiments.
- Add tests for `repeat`, `pause`, and end-of-session feedback generation success/failure paths.

Blockers and decisions taken

- Decision: keep business behavior unchanged by default (existing production timings remain the same), while exposing parameters for controlled tuning.
- No blockers in implementation; pending only broader real-device validation with family test cycle.

## Implementation Cycle Update (2026-03-07 - Config Source)

Completed items

- Implemented lightweight app-level configuration source for speaking-session timing (`VoiceChatSessionConfig`) loaded from environment values.
- Wired central config into runtime construction so `SpeechService` and `VoiceChatController` share one timing source.
- Added unit tests for config parsing with valid values and fallback behavior.

New priorities discovered during testing

- Build a small in-app debug panel to adjust timing values without app restart during family tests.
- Persist last-used tuning profile locally to compare test sessions.

Blockers and decisions taken

- Decision: keep safe defaults in code and allow optional environment override keys.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Flutter Stable + Android Build Recovery)

Completed items

- Upgraded local Flutter SDK to latest stable (`3.41.4`) with Dart `3.11.1`.
- Updated Android toolchain versions in project:
  - Gradle wrapper to `8.7`
  - Android Gradle Plugin to `8.6.0`
  - Kotlin Gradle plugin to `2.1.0`
- Updated app compatibility dependencies/constraints:
  - Dart SDK constraint in `pubspec.yaml` to `>=3.0.0 <4.0.0`
  - `speech_to_text` to `^7.3.0`
- Removed stale generated Android file `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` that referenced obsolete plugin package names.
- Validated successful APK generation in split mode (`--split-per-abi`) for real-device testing.

New priorities discovered during testing

- Consider upgrading Java compile target from 8 to 17 in Android config to remove obsolete source/target warnings and align with modern AGP defaults.
- Plan a dependency refresh pass for remaining outdated packages flagged by `flutter pub get`.

Blockers and decisions taken

- Decision: prioritize minimal compatibility upgrades required to restore release APK build first, then handle wider dependency modernization in a dedicated cycle.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Web STT Stability)

Completed items

- Hardened `SpeechService` against overlapping web speech-recognition starts by serializing `listen()` calls.
- Added defensive recognizer cleanup before new listen attempts and a single retry path after a short settle delay when web start fails due to stale recognition state.
- Kept current conversation behavior unchanged (same listen/pause timings and same fallback flow), focusing only on runtime stability.

New priorities discovered during testing

- Add targeted unit tests around speech-service concurrency behavior (single-flight listen and retry path) with a mockable speech adapter.
- Add a lightweight telemetry counter for STT start failures to confirm fix impact on real devices/browsers.

Blockers and decisions taken

- Decision: prefer graceful retry and null fallback over surfacing STT exceptions to UI, preserving uninterrupted conversation loop behavior.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Resume Stability)

Completed items

- Added a short resume grace period in `VoiceChatController` to prevent immediate inactivity auto-pause right after tapping `Retomar conversa`.
- Updated conversation loop behavior to ignore silent-turn counting while this resume grace window is active.
- Added automated test coverage for resume behavior to ensure conversation remains active briefly after manual resume.

New priorities discovered during testing

- Make resume grace period configurable from session environment settings for easier UX tuning during family tests.
- Add explicit UI hint during grace period (for example: "Listening resumed") to clarify temporary inactivity handling.

Blockers and decisions taken

- Decision: keep grace period short (2 seconds default) to reduce false immediate pauses without masking genuine inactivity.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Local Persistence to Hive)

Completed items

- Migrated local persistence implementation from `SharedPreferences` to Hive in `LocalSessionHistoryRepository`.
- Added `hive_flutter` dependency and initialized Hive at app startup in `main.dart`.
- Preserved existing repository behavior for: session list save/load and daily challenge read/update.
- Validated migration with current voice-chat unit tests (all passing).

New priorities discovered during testing

- Add targeted tests for Hive-backed repository behavior (session ordering, max-cap trimming, and daily challenge rollover).
- Plan a one-time migration strategy if previous production builds already stored data only in `SharedPreferences`.

## Implementation Cycle Update (2026-03-07 - Speech Speed 0.25x)

Completed items

- Added explicit `0.25x` command handling in `VoiceChatController` (`0.25x`, `0,25x`, `quarter speed`, `um quarto da velocidade`).
- Exposed `0.25x` in the speech-speed chips on `voice_chat_page.dart` so users can select it directly in UI.
- Improved speed label formatting to preserve two decimals when needed, avoiding `0.25x` being shown as `0.3x`.
- Added unit test coverage for explicit `0.25x` command behavior and updated speech-rate expectations to align with current `_baseTtsRate = 0.7`.

New priorities discovered during testing

- Add a tiny shared formatter/helper for speed labels to avoid duplicated formatting logic between controller and page.
- Add an integration-style widget test validating that selecting `0.25x` chip triggers the expected `setSpeechSpeedMultiplier` flow.

Blockers and decisions taken

- Decision: keep clamp as `clamp(0.2, 1.0)` to preserve a usable slowest floor while allowing higher base-rate tuning.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Remove 0.25x)

Completed items

- Removed `0.25` from supported internal multipliers in `VoiceChatController`.
- Removed explicit quarter-speed command handling (`0.25x`, `0,25x`, `quarter speed`, `um quarto da velocidade`).
- Removed `0.25x` option from speech-speed chips in `voice_chat_page.dart`.
- Removed dedicated unit test for explicit `0.25x` command.
- Re-ran voice-chat controller tests successfully.

New priorities discovered during testing

- If ultra-slow mode is needed later, prefer feature-flagged rollout instead of default exposure in the primary UI.

Blockers and decisions taken

- Decision: keep supported speed set focused on `0.5x`, `1.0x`, `1.5x`, `2.0x`.
- No blockers.

Blockers and decisions taken

- Decision: keep storage payload as JSON strings in Hive to avoid introducing adapter/codegen complexity in this cycle.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Practice Hub and Roadmap Code Progress)

Completed items

- Integrated `resumeGracePeriod` environment config into runtime controller wiring.
- Added application-level `PracticeHubController` to orchestrate daily challenge, weekly progress snapshot, and session history loading without putting business logic in widgets.
- Added `Practice Hub` UI entry in `VoiceChatPage` (modal bottom sheet) with:
  - `Previous Sessions` list (latest local sessions)
  - `Weekly Progress` metrics (minutes, active days, most used focus, streak)
  - `Daily Challenge` card with completion action
- Added always-visible daily challenge banner in main voice screen for continuity and motivation.
- Added premium-ready feature flag usage in UI (locked labels for premium insights and daily-plus extras), preserving architecture isolation without payment enablement.
- Improved status panel readability and added explicit resume-grace hint in UI.
- Extended automated tests:
  - `VoiceChatSessionConfig` covers `VOICE_CHAT_RESUME_GRACE_MS`
  - `VoiceChatController` covers `repeat`, `pause`, and session persistence after feedback generation

New priorities discovered during testing

- Add integration tests for `PracticeHubController` with Hive-backed repository to validate end-to-end loading state and data refresh after feedback.
- Add optional filters/search in `Previous Sessions` for higher-volume usage.

Blockers and decisions taken

- Decision: keep initial progress/history UX as a modal `Practice Hub` to ship quickly with low navigation overhead; can later evolve into dedicated routed screens.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Initial Dashboard Entry)

Completed items

- Added a new initial dashboard screen (`InitialDashboardPage`) as the app entry after splash, providing a more professional first-touch UX before starting voice chat.
- Added quick-menu cards and footer navigation affordances in the dashboard for core product areas (dashboard, practice, and session controls).
- Kept current voice workflow untouched by routing users to `VoiceChatPage` as the main CTA (`Start Practice Session`) and by passing contextual startup hints when entering from quick actions.

New priorities discovered during testing

- Add a dedicated routed settings page (instead of hint-only navigation) for voice/session preferences and onboarding toggles.
- Add lightweight dashboard integration tests to validate splash-to-dashboard navigation and primary CTA behavior.

Blockers and decisions taken

- Decision: prioritize low-risk UX improvement by introducing a dashboard entry page without refactoring the existing voice-chat internals.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Routed Footer Screens)

Completed items

- Replaced footer placeholders with real routed screens for `Practice` and `Session`.
- Added `PracticeOverviewPage` using `PracticeHubController` + existing `PracticeHubSheet` as a dedicated screen, preserving business logic in application/infrastructure layers.
- Added `SessionSettingsPage` with session-start preferences and direct entry to `VoiceChatPage`.
- Added centralized route constants (`DashboardRoutes`) and wired named routes in `MaterialApp`.
- Updated `SplashPage` and `InitialDashboardPage` to navigate through named routes, improving navigation consistency.

New priorities discovered during testing

- Persist session settings preferences locally (currently local UI state only).
- Add widget tests for footer navigation transitions (`Dashboard` <-> `Practice` <-> `Session`).

Blockers and decisions taken

- Decision: reuse existing `PracticeHubSheet` in the new screen to avoid duplicating UI/business logic while shipping faster.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Dedicated Language Mode)

Completed items

- Added a dedicated `Language Mode` screen (`LanguageModePage`) with explicit choices: `Auto`, `English (US)`, and `Portugues (BR)`.
- Added local preference persistence via `LocalUserPreferencesRepository` (Hive) for preferred conversation language.
- Wired dashboard `Language Mode` quick card to the new dedicated screen route.
- Updated `VoiceChatPage` to load preferred language before starting conversation and to save changes when user switches language in chat.

New priorities discovered during testing

- Add the same language preference entry point in `Session Settings` for discoverability parity.
- Add widget tests covering language-preference load/save flow and startup application in chat page.

Blockers and decisions taken

- Decision: keep persistence lightweight in Hive using enum `name` strings for compatibility and simplicity.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Java 17 Android Compile Target)

Completed items

- Updated Android app compile target to Java 17 in `android/app/build.gradle`:
  - `sourceCompatibility = JavaVersion.VERSION_17`
  - `targetCompatibility = JavaVersion.VERSION_17`
  - `kotlinOptions.jvmTarget = "17"`
- Added Android subproject-level fallback in `android/build.gradle` to enforce Java/Kotlin 17 defaults for modules with Android plugin, reducing obsolete Java 8 warnings from transitive plugin modules.
- Validated release APK build success after migration using `flutter build apk --release --split-per-abi`.

New priorities discovered during testing

- Consider adding a short CI smoke build step for Android release to catch future Gradle/JDK drift earlier.

Blockers and decisions taken

- Decision: prefer true compile-target modernization (Java 17) instead of suppressing warnings with `-Xlint:-options`.
- No blockers.

## Implementation Cycle Update (2026-03-07 - App Language in Settings)

Completed items

- Added app-level language support with two interface locales: `en-US` and `pt-BR`.
- Implemented `AppSettingsController` + `AppSettingsScope` to propagate selected app language across UI rebuilds.
- Added persistence for app language in `LocalUserPreferencesRepository` using Hive.
- Added language selection in `Session Settings` (`App Language`) with immediate app UI update.
- Localized key dashboard/practice/settings/language-page labels using a shared helper (`appText`).

## Implementation Cycle Update (2026-03-07 - Desktop Lateral Spacing)

Completed items

- Added a reusable responsive wrapper (`ResponsiveContentShell`) to apply desktop/tablet side spacing with centered max-width content.
- Applied responsive lateral spacing to core dashboard flow screens:
  - `InitialDashboardPage`
  - `VoiceChatPage`
  - `PracticeOverviewPage`
  - `LanguageModePage`
  - `SessionSettingsPage`
- Preserved mobile behavior by keeping side spacing disabled on small widths.

New priorities discovered during testing

- Add golden/widget tests for breakpoint behavior to avoid future regressions in desktop layout spacing.
- Consider applying the same responsive shell to any future full-screen pages to keep visual consistency.

Blockers and decisions taken

- Decision: centralize desktop spacing policy in one shared presentation widget to avoid duplicated breakpoint logic.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Premium Layout Profiles)

Completed items

- Evolved `ResponsiveContentShell` to support configurable layout profiles: `compact`, `balanced`, and `premium`.
- Added convenient constructors for profile selection (`ResponsiveContentShell.premium` and `ResponsiveContentShell.compact`) while keeping a safe default profile.
- Applied `premium` profile to the main routed screens (`Dashboard`, `Voice Chat`, `Practice Overview`, `Language Mode`, and `Session Settings`) to increase side breathing room on desktop and ultrawide displays.

New priorities discovered during testing

- Add visual regression coverage (desktop widths 1024, 1280, 1600+) to validate profile spacing over time.
- Consider exposing profile selection through feature flags for controlled UX experiments.

Blockers and decisions taken

- Decision: keep profile logic centralized in presentation layer to avoid scattered breakpoint constants.
- No blockers.

New priorities discovered during testing

- Expand localization coverage to remaining voice-chat screen strings and status messages for full parity.
- Add widget tests validating language toggle behavior and persistence across app restarts.

Blockers and decisions taken

- Decision: keep localization lightweight with internal `appText` helper for this cycle, avoiding full intl package rollout.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Sprint 1 Delivery)

Completed items

- Added targeted STT reliability hardening in `SpeechService`:
  - introduced single-flight-safe recognizer adapter wiring for testability
  - kept web retry path and made second-failure fallback return `null` instead of surfacing exceptions
  - added lightweight `sttStartFailureCount` counter to track recognition start failures
- Added focused STT web-flow tests (`speech_service_test.dart`) covering:
  - concurrent `listen()` serialization
  - first-failure + retry success path
  - first-failure + retry failure path with counter validation
- Added integration tests for `PracticeHubController` + Hive-backed repository paths (`practice_hub_controller_integration_test.dart`) covering:
  - load of sessions + daily challenge + weekly snapshot
  - refresh behavior after new session persistence
- Added app-language persistence test across restart-like controller lifecycle (`app_settings_controller_persistence_test.dart`).
- Expanded bilingual UX parity for voice-chat support UI:
  - localized remaining helper/action strings in `VoiceChatPage`
  - localized `PracticeHubSheet` labels and support messages via `appText`
  - kept explicit resumed-listening hint visible in both locales during resume grace period
- Added controller-level tests to validate language alignment and continuity tone:
  - response language follows user-selected `en_US` / `pt_BR` mode
  - inactivity pause message tone validated for both languages
- Updated AI response prompt rule to keep strict same-language replies in Portuguese mode (no forced mixed-language line).

New priorities discovered during testing

- Surface `sttStartFailureCount` in a lightweight debug/diagnostic panel to observe browser/device stability during family tests.
- Add widget-level coverage for localized `VoiceChatPage` controls and resumed-listening hint rendering under app-language toggles.
- Consider localizing focus option labels while preserving stable internal focus identifiers for analytics/prompt consistency.

Blockers and decisions taken

- Decision: keep STT failure telemetry in-memory and minimal for this cycle (counter only), avoiding analytics coupling before family-test validation.
- Decision: preserve current domain flow and persistence contracts while adding integration-style tests around existing Hive implementation.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Sprint 2 Delivery)

Completed items

- Improved weekly progress usefulness with stronger consistency/streak emphasis:
  - expanded `WeeklyProgressSnapshot` with `consistencyPercent` and `consistencyLabel`
  - surfaced consistency status in `PracticeHubSheet` next to minutes/active-days/streak metrics
- Added optional search/filter flow for `Previous Sessions` in `PracticeHubSheet`:
  - search by focus/feedback text
  - focus-area dropdown filter
  - new `PracticeHubController` filtered-state notifiers and refresh methods
- Improved pedagogical end-of-session report reliability in `VoiceChatController`:
  - added normalization path that enforces structured report headings
  - added deterministic fallback report with level estimate (`Beginner` / `Intermediate` / `Advanced`)
  - guaranteed "Try These 3 Sentences" section with exactly three short repetition lines in fallback
- Increased daily challenge stickiness:
  - persisted challenge completion history in Hive (`DailyChallengeHistory`)
  - exposed history in controller/UI (last-7-days completion signal + current streak)
  - added one-tap "Mark challenge as done" action in the always-visible main-session daily banner
- Added/updated tests for Sprint 2 scope:
  - `voice_chat_controller_test.dart` now validates feedback normalization and feedback-failure fallback paths
  - `practice_hub_controller_integration_test.dart` now validates filter/search behavior and daily challenge history persistence

New priorities discovered during testing

- Add widget tests for `PracticeHubSheet` search/filter interactions and localized consistency labels.
- Add parser-level validation utility for AI feedback to enforce exactly 3 sentence lines even when model partially follows instructions.
- Evaluate keeping top N repeated challenge topics to personalize next daily micro-goal suggestions.

Blockers and decisions taken

- Decision: keep challenge-history model lightweight (`dateKey` list) in Hive JSON to avoid adapter/codegen overhead in this cycle.
- Decision: keep report heading contract in English for stable parsing while preserving body language alignment (`en-US`/`pt-BR`) in fallback texts.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Sprint 3 Delivery)

Completed items

- Settings and preferences hardening:
  - implemented persisted session UI preferences (`SessionUiPreferences`) for:
    - auto resume listening after bot speech
    - show startup tips when opening chat
  - added `SessionSettingsController` in application layer to keep preference orchestration outside widgets
  - wired `SessionSettingsPage` to load/save preferences from Hive via controller
  - applied persisted `autoResumeListening` behavior in runtime by wiring setting into `VoiceChatController`
  - applied persisted startup-tip behavior when opening `VoiceChatPage`
- Responsive quality guardrails:
  - added widget tests for premium desktop breakpoints in `ResponsiveContentShell`:
    - 1024 width -> max content 940
    - 1280 width -> max content 1024
    - 1600 width -> max content 1120
- Validation:
  - full test suite executed successfully after changes (`29 passed, 0 failed`)

New priorities discovered during testing

- Add widget coverage for `SessionSettingsPage` load/persist interactions and language + session settings combined flow.
- Add breakpoint tests for `balanced` and `compact` profiles to protect all responsive profiles, not only `premium`.
- Consider adding explicit persisted setting for default practice focus to reduce pre-session setup friction.

Blockers and decisions taken

- Decision: keep session preferences persisted in existing Hive box as primitive booleans for low-risk rollout.
- Decision: preserve default behavior (`autoResumeListening=true`, `showStartupTips=true`) when preference keys are absent to stay backward compatible.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Voice Speed Commands)

Completed items

- Expanded in-session command support to adjust IA speech speed with clearer explicit intents:
  - added recognition for explicit speed-down phrases (`slower`, `decrease speed`, `diminuir velocidade`, `reduzir velocidade`)
  - preserved existing speed-up and normal-speed commands (`speed up`, `aumentar velocidade`, `normal speed`)
- Kept the same safe speed boundaries and incremental behavior already in controller logic:
  - min 25%
  - max 70%
  - step 10%
- Added focused command tests in `voice_chat_controller_test.dart` for Portuguese explicit commands:
  - `aumentar velocidade`
  - `diminuir velocidade`

New priorities discovered during testing

- Add a lightweight UI control (chip/slider) for speech speed as an alternative to voice-only commands.
- Expose current speech speed indicator in status area to improve user visibility.

Blockers and decisions taken

- Decision: keep speed controls command-based in this cycle for low-friction rollout and no UI complexity increase.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Speech Speed Multipliers)

Completed items

- Evolved speech-speed control model from percent-style feedback to explicit multiplier presets:
  - `0.5x`
  - `1.0x`
  - `1.5x`
- Added visible in-session speed controls in `VoiceChatPage` with selectable chips for the three multipliers.
- Extended controller command handling to support literal multiplier intents in voice input:
  - `0.5x` / `0,5x`
  - `1x` / `1.0x` / `1,0x`
  - `1.5x` / `1,5x`
- Preserved bilingual command behavior and user feedback messages in `en-US` / `pt-BR`.
- Added and updated controller tests for the new multiplier behavior and literal command parsing.

New priorities discovered during testing

- Persist selected speech-speed multiplier across app restarts for continuity between sessions.
- Add widget tests for speed-chip selection flow in `VoiceChatPage`.

Blockers and decisions taken

- Decision: keep internal TTS mapping proportional to base rate while exposing user-facing controls only as multipliers.
- No blockers.

## Implementation Cycle Update (2026-03-07 - AI Fallback Diagnostics on Device)

Completed items

- Refactored Gemini integration to throw typed failures (`AIServiceException`) with explicit categories:
  - missing key
  - unauthorized/forbidden
  - rate limit/quota
  - network/timeout
  - service unavailable
  - invalid response
- Added request timeout + safer JSON parsing in `GeminiService` to avoid collapsing all failures into one generic branch.
- Updated `VoiceChatController` to speak actionable bilingual fallback messages based on real error category instead of always saying only a generic retry phrase.
- Added test coverage in `voice_chat_controller_test.dart` for network-classified AI fallback messaging.

New priorities discovered during testing

- Add lightweight non-sensitive telemetry counters for AI error categories (debug and release) to compare real-device stability.
- Add a small diagnostics panel in app settings to show latest STT/TTS/AI failure category for faster troubleshooting.

Blockers and decisions taken

- Decision: keep fallback messages concise and actionable without exposing raw API payloads or secrets.
- Blocker: could not run live Gemini probe in this environment due terminal session instability; real-device validation will confirm after rebuild.
