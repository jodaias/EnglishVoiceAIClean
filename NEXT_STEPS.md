# Next Steps

This file is the current action plan for evolving the app as a high-quality English learning product.

## Duolingo-Style Reading & Listening (new — 2026-03-11)

Full transformation plan documented in [PLAN_DUOLINGO_READING_LISTENING.md](PLAN_DUOLINGO_READING_LISTENING.md).

### Summary

- Transform linear quiz module into gamified learning path with units, lessons, and progressive unlocking.
- Add 8+ exercise types: listen & type, fill in the blank, word order, translate, match pairs, speak the sentence, true/false.
- Implement XP system, hearts (lives), crowns per unit, and streak integration.
- Duolingo-inspired UI: bubble trail, progress bar, animated feedback, celebration animations.
- Content strategy: curated catalog (Phase 1) → AI-generated via Gemini (Phase 2) → spaced repetition (Phase 3).
- MVP in ~5 sprints (Domain → Catalog → Controller → Widgets → Lesson Page).

### Current execution status (2026-03-11)

- SQLite cross-platform bootstrap hotfix applied (web/desktop):
  - Added `initializeDatabaseFactory()` to configure `sqflite` global factory before any `openDatabase` call.
  - Web now initializes `databaseFactoryFfiWeb`; Windows/Linux/macOS now initialize `databaseFactoryFfi`.
  - `main.dart` now runs this initialization before `AppDatabase.instance.open()` to avoid `Bad state: databaseFactory not initialized`.
  - `AppDatabase.open()` now uses `dbName` directly on web (without `getDatabasesPath`) to avoid `SqfliteFfiWebException` from unsupported path resolution flow.
  - Ran `dart run sqflite_common_ffi_web:setup` and generated required web binaries: `web/sqflite_sw.js` and `web/sqlite3.wasm`.

- Sprint 0 (API + SQLite) implemented in code and tests.
- New local database layer added:
  - `AppDatabase` with schema, indexes, versioning, and migration entrypoint
  - First-run curated seed (`seed_data.dart`) for Unit 1 and Unit 2
- New DAOs added:
  - `LearningUnitsDao`, `ExercisesDao`, `UserProgressDao`, `SpacedRepetitionDao`
- New API abstraction + implementations added:
  - `LearningApiService` contract
  - `LocalLearningApiService` backed by SQLite DAOs
  - `RemoteLearningApiService` stub for future REST migration
- Runtime integration added:
  - SQLite initialization in `main.dart` together with Hive startup
- Documentation added:
  - `docs/learning_sqlite_schema.md` (schema, indexes, seed, migration policy)
- New SQLite in-memory tests added:
  - DAO tests (units, exercises, user progress, spaced repetition)
  - Seed integrity test
  - LocalLearningApiService integration test
- Validation: Sprint 0 focused SQLite suite passing.

- Sprint 1 (Foundations) implemented in code and tests.
- New domain entities added for learning path and progression:
  - `ExerciseType`, `LessonExercise`, `Lesson`, `LearningUnit`
  - `LessonProgress`, `UnitProgress`, `UserProgress`, `XpReward`
- New persistence layer added:
  - `LearningProgressRepository` (application contract)
  - `LocalLearningProgressRepository` (Hive + JSON)
- New automated tests added:
  - `test/features/voice_chat/domain/entities/learning_path_entities_test.dart`
  - `test/features/voice_chat/infrastructure/local/local_learning_progress_repository_test.dart`
- Validation: focused test run completed with 9/9 tests passing.

- Sprint 2 (Catalog + Validation) implemented in code and tests.
- New application services added:
  - `ExerciseValidator` with rules for all `ExerciseType` variants
  - `XpCalculator` for per-exercise and perfect-lesson XP rules
  - `HeartsManager` with cooldown refill and relaxed mode support
- New content catalog added:
  - `LessonContentCatalog` with Unit 1 (`Greetings`) and Unit 2 (`At a Cafe`)
  - 3 lessons per unit, 18 exercises per unit (36 total), with full exercise-type coverage
- New automated tests added:
  - `test/features/voice_chat/application/exercise_validator_test.dart`
  - `test/features/voice_chat/application/xp_calculator_test.dart`
  - `test/features/voice_chat/application/hearts_manager_test.dart`
  - `test/features/voice_chat/application/lesson_content_catalog_test.dart`
- Validation: Sprint 2 focused tests 15/15 and voice_chat suite 44/44 passing.

- Sprint 3 (Lesson Controller) implemented in code and tests.
- New orchestration layer added:
  - `LessonController` with `ValueNotifier` states for exercise index, selected answer, feedback, hearts, XP, progress, completion and summary
  - Full lesson loop: show -> submit -> feedback -> continue -> summary
- Runtime integrations added:
  - TTS playback via `LearningAudioService` (`playCurrentPromptAudio`)
  - STT capture for speaking exercises via `PronunciationCaptureService` (`captureSpokenAnswer`)
- Persistence integration added:
  - Saves lesson completion into `LearningProgressRepository` with score, attempts, XP aggregation, hearts snapshot, and crowns increment (up to 5)
- New automated tests added:
  - `test/features/voice_chat/application/lesson_controller_test.dart`
- Validation: lesson controller tests 4/4 and voice_chat suite 48/48 passing.

- Sprint 4 (Learning Path Controller) implemented in code and tests.
- New orchestration layer added:
  - `LearningPathController` with `ValueNotifier` states for units, unlock/completion map, total XP, streak, loading and errors
  - Progressive unlock evaluation based on completion of the previous unit
  - Crown synchronization logic per unit (bounded to 0..5)
- Integration added:
  - Optional integration with `PracticeHubController` to reuse weekly streak signal
  - `registerLessonResult()` persists lesson progress via `LearningApiService` and refreshes learning-path state
- New automated tests added:
  - `test/features/voice_chat/application/learning_path_controller_test.dart`
- Validation: learning-path tests passing and full `voice_chat` suite 57/57 passing.

- Sprint 5 (Exercise Widgets baseline) implemented in code and tests.
- New presentation widgets added:
  - `ProgressBarWidget` (lesson progress percentage)
  - `HeartsDisplay` (remaining lives visual)
  - `FeedbackOverlay` (correct/incorrect visual feedback with continue action)
- New exercise renderer added:
  - `LessonExerciseRenderer` with per-type inputs for multiple choice, listen/select, listen/type, fill-in-blank, word-order, translate, true/false, match-pairs and speak-the-sentence
  - Unified callback contract for answer selection and audio/speech actions
- New automated tests added:
  - `test/features/voice_chat/presentation/lesson_ui_widgets_test.dart`
- Validation: presentation tests 15/15 passing and focused application regression tests 13/13 passing.

- Sprint 5 refinements completed.
- UI gaps closed:
  - `ExerciseMatchPairs` upgraded to interactive two-column pairing flow with selection highlight and pair replacement handling.
  - `ExerciseSpeakSentence` now displays pronunciation accuracy text + progress bar.
  - `FeedbackOverlay` now has animated entrance and animated background emphasis by feedback state.
- Test coverage expanded:
  - Added match-pairs interaction test and speak-accuracy rendering test in `test/features/voice_chat/presentation/lesson_ui_widgets_test.dart`.
- Validation update: presentation tests 17/17 passing.

- Sprint 6 (Lesson Page + Summary Page) implemented in code and tests.
- New UI flow pages added:
  - `LessonPage` with complete CHECK/CONTINUE loop driven by `LessonController`
  - `LessonSummaryPage` with animated XP counter and score/hearts summary
- Lesson runtime behavior delivered:
  - Top HUD with progress bar and hearts
  - Per-type exercise rendering via `LessonExerciseRenderer`
  - Animated exercise transitions (`AnimatedSwitcher`)
  - Post-answer feedback overlay integrated in-page
  - Exit confirmation dialog and summary navigation on completion
- Routing updates:
  - Added `/lesson` and `/lesson-summary` route constants and route registration in `main.dart`
- New automated tests added:
  - `test/features/voice_chat/presentation/lesson_page_test.dart`
- Validation update: presentation tests 19/19 passing.

- Sprint 7 (Learning Path Page) implemented in code and tests.
- New trail UI added:
  - `LearningPathPage` with unit banners, horizontal bubble rows, and connected lesson nodes
  - Header with XP, streak and hearts
  - Open-lesson flow from node taps with refresh after returning
- New reusable widget added:
  - `LessonNodeWidget` with states: locked, available, completed and perfect
- Controller enhancement:
  - `LearningPathController` now exposes `availableHeartsNotifier` for path header state
- Routing/dashboard integration:
  - Added `/learning-path` route and route constant
  - Dashboard quick menu now opens the learning path
- New automated tests added:
  - `test/features/voice_chat/presentation/learning_path_page_test.dart`
- Validation update: Sprint 7 focused presentation tests 10/10 passing.

- Sprint 8 (Expanded Content) implemented in code and tests.
- Catalog expansion delivered:
  - Units 3-5 (Beginner): Getting Around, Daily Routine, Shopping
  - Units 6-8 (Intermediate): At the Airport, At Work, Health and Doctor
  - Units 9-10 (Intermediate): Making Plans, Telling Stories
- Content quality updates:
  - Added structured bilingual prompts (`promptEn`/`promptPt`) across expanded units
  - Kept mixed exercise distribution (option, listening, text, order, matching, speaking, true/false)
- Test integrity updates:
  - `lesson_content_catalog_test.dart` now validates 10 units, beginner/intermediate split (5/5), lesson/exercise volume per unit, and per-type bilingual content structure
- Validation update: Sprint 8 focused application tests 6/6 passing.

- Sprint 9 (Audio, Haptics and Polish) implemented in code.
- Feedback audio and haptics delivered:
  - Added `LessonFeedbackAudioService` abstraction and `SystemLessonFeedbackAudioService` implementation
  - Integrated sound playback for correct answer, wrong answer, and lesson completion in `LessonPage`
  - Added haptic feedback on option selection, answer result, and lesson completion
- UX polish delivered:
  - Feedback flow now combines animated overlay + tactile/audio response for micro-interaction reinforcement
  - Lesson summary now shows a Lottie celebration block for perfect lessons (100% score)
- Compatibility notes:
  - Sound implementation currently uses system sound fallback and is ready to swap to dedicated MP3 asset playback in the same service interface.
- Validation update: focused presentation tests 12/12 passing.

- Sprint 10 (AI generation foundation) implemented in code and tests.
- New AI generation components added:
  - `ExerciseGeneratorService` with Gemini prompt execution pathway
  - Structured per-type prompt templates and strict JSON schema expectations
  - Automatic generated-exercise validation by type (options/text/tokens/pairs/speech/boolean)
  - Local generation cache abstraction + Hive-backed cache implementation
  - Surprise-lesson generation method (`generateSurpriseLesson`) with mixed type sequencing
- New files:
  - `lib/features/voice_chat/infrastructure/ai/exercise_generator_service.dart`
  - `lib/features/voice_chat/infrastructure/ai/exercise_generation_cache.dart`
- New tests:
  - `test/features/voice_chat/infrastructure/ai/exercise_generator_service_test.dart`
- Validation update: Sprint 10 focused tests 10/10 passing.
- Hub integration delivered:
  - `PracticeHubSheet` now exposes "Start surprise lesson" with generation loading state.
  - `PracticeOverviewPage` now lets users choose topic + difficulty, generates a lesson on-the-fly, and opens `LessonPage` with generated content.
  - New widget test added for surprise-lesson CTA behavior.

- Sprint 11 (Spaced Repetition) implemented in code and tests.
- New review-flow components added:
  - `SpacedRepetitionService` with progression rule: wrong -> 1 day, correct -> 3 days, correct -> 7 days, correct -> remove from queue.
  - `LearningApiService` expanded with review queue upsert/remove operations; local and remote implementations updated.
  - `LessonController` now reports per-exercise results to spaced-repetition service after lesson persistence.
- Hub and UX integration delivered:
  - `PracticeHubController` now loads pending review count and can build a dynamic daily-review lesson from due queue items.
  - `PracticeHubSheet` now exposes "Daily Review" section with due count and start action.
  - `PracticeOverviewPage` now opens a generated daily-review lesson and refreshes queue state after completion.
- New tests:
  - `test/features/voice_chat/application/spaced_repetition_service_test.dart`
  - `test/features/voice_chat/presentation/practice_hub_sheet_test.dart` (daily review CTA)
- Validation update: focused Sprint 11 tests passing.

### Next execution target

- Sprint 12: iniciar integracao e migracao final para consolidar `/learning-path` como entrada principal.

## Video Call Mode (new — 2026-03-07)

### Done

- Created `VideoCallPage` with immersive video-call-style layout (avatar full-screen, captions overlay, floating controls)
- Added `/video-call` route and menu entry on dashboard alongside existing Voice Chat
- Both modes (Voice Chat and Video Call) coexist — same STT→AI→TTS loop, different UI

### Next iterations

1. **Avatar upgrade** — replace Lottie robot with Rive humanoid avatar (lip-sync state machine, expressions)
2. **Camera self-view** — add optional camera preview in corner using `camera` package
3. **Animated background** — subtle particle/gradient animation behind avatar
4. **Full conversation history** — expandable drawer to see all messages (not just last 2 captions)
5. **Picture-in-picture** — mini floating window when navigating away (Android PiP API)
6. **Screen wake lock** — keep screen on during active call

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

## Implementation Cycle Update (2026-03-07 - Scene Assets on Mobile)

Completed items

- Fixed `SessionScene.assetPath` values to use Flutter asset keys with `assets/` prefix:
  - `assets/images/scenes/studio_scene.png`
  - `assets/images/scenes/city_scene.png`
  - `assets/images/scenes/library_scene.png`
- Restored scene background rendering on Android builds where image loading was previously falling back to gradient.

New priorities discovered during testing

- Add a small widget test for `voice_chat_page.dart` background rendering per `SessionScene` to catch asset-key regressions.
- Add an optional pre-cache step (`precacheImage`) when opening chat to avoid first-frame background pop-in on lower-end devices.

Blockers and decisions taken

- Decision: keep explicit per-file asset registration in `pubspec.yaml` for now (instead of directory wildcard) to preserve tighter asset control.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Editable STT Before Send)

Completed items

- Added transcript review flow in `VoiceChatController` with explicit states/notifiers for pending recognized text.
- Added user actions to confirm edited text (`Send`) or discard and capture again (`Speak again`) before AI request.
- Updated `VoiceChatPage` with an inline editable panel that appears after STT capture and before message submission.
- Kept default controller behavior unchanged for existing tests/flows and enabled review mode explicitly in the voice-chat page.
- Added unit test coverage ensuring AI response generation waits for user confirmation when input review is enabled.

New priorities discovered during testing

- Add a persisted toggle in session settings to enable/disable transcript review mode per user preference.
- Add widget tests for the review panel actions (`Send` and `Speak again`) to protect UI behavior.

Blockers and decisions taken

- Decision: review mode is enabled at runtime in the chat page while controller default remains disabled to preserve backward compatibility in current tests.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Web dotenv Asset 404 Fix)

Completed items

- Fixed web dotenv loading to avoid requesting `/assets/.env`, which can return 404 for dot-prefixed asset names on web servers.
- Updated startup env loading in `main.dart`:
  - Web uses `env/web.env`
  - Non-web keeps `.env`
- Registered `env/web.env` in `pubspec.yaml` assets.
- Added `env/web.env` template file with non-secret placeholders for web builds.

New priorities discovered during testing

- Consider centralizing environment loading in a dedicated bootstrap helper to keep startup logic easier to extend.
- Review user-facing fallback text that currently mentions only `.env` so web guidance can mention `env/web.env` when applicable.

Blockers and decisions taken

- Decision: keep `.env` for mobile/desktop compatibility and use `env/web.env` only for web target to minimize migration risk.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Optional Edit Flow + Keyboard Safe)

Completed items

- Updated transcript review flow so editing is optional during voice capture review.
- Added auto-send behavior (2s) when review mode is enabled but user does not interact with the recognized text.
- Auto-send is canceled as soon as the user starts typing, preserving full manual control for corrections.
- Updated review status and helper text to clarify that editing is optional.
- Improved keyboard handling in voice chat using animated bottom inset padding so the edit field is not covered while typing.

New priorities discovered during testing

- Add a visible countdown indicator for auto-send to make timing explicit.
- Add a widget test validating keyboard inset behavior during edit mode.

Blockers and decisions taken

- Decision: keep review mode user-configurable via session settings; when enabled, default action is non-blocking auto-send unless the user chooses to edit.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Better Transcript Selection In Review)

Completed items

- Improved `auto` language capture behavior when `reviewBeforeSend` is enabled.
- Instead of accepting the first non-empty capture, the controller now captures both locale candidates (`en_US` and `pt_BR`) and selects the clearest transcript.
- Added a lightweight text-quality scoring heuristic (word count, text length, punctuation signal) to pick the better candidate before showing it in review.
- Added automated test coverage validating that review mode chooses the better candidate even when the first capture is weaker.

New priorities discovered during testing

- Evaluate adding language-confidence scoring from STT plugin if exposed in future package versions.
- Add optional debug logging in dev mode for selected candidate and score to speed up real-device tuning.

Blockers and decisions taken

- Decision: keep this stronger candidate-selection path only when review mode is enabled, preserving current latency profile for fully automatic mode.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Pencil Edit + Strict Review Send)

Completed items

- Added explicit pencil action in chat review UI so users intentionally enter edit mode before sending.
- Changed review flow behavior: when `reviewBeforeSend` is enabled, recognized message is no longer auto-sent.
- Enforced controller rule: confirmation only succeeds after user starts editing in review mode.
- Kept `Speak again` path unchanged for recapture without sending wrong transcript.
- Added regression test ensuring review mode does not send before edit and that confirm fails until edit starts.

New priorities discovered during testing

- Add widget test for the pencil button to verify read-only to editable transition in UI.
- Consider optional "Confirm without edit" secondary action in future if users request a faster strict-review flow.

Blockers and decisions taken

- Decision: strict review mode now prioritizes user control over speed by requiring explicit edit intent before send.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Conversation Area Expansion)

Completed items

- Improved `voice_chat_page.dart` vertical layout to prioritize message history area on smaller screens.
- Added compact-height behavior that lets users collapse secondary session panels (tips, speed controls, challenge card, and stat cards) via a toggle action.
- Reduced avatar height when compact panels are hidden and wrapped the conversation list in a dedicated container, increasing perceived and usable chat space.
- Kept bilingual labels (`en-US` and `pt-BR`) for the new compact panel toggle.

New priorities discovered during testing

- Add a widget test for compact-height mode to guarantee that collapsing panels increases visible conversation area without regressions.
- Auto-scroll to latest message after each new turn to further improve chat readability in long sessions.

Blockers and decisions taken

- Decision: keep all secondary learning/session tools available, but make them collapsible only when vertical space is constrained.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Compact Mode Visibility Fix)

Completed items

- Adjusted compact mode in `voice_chat_page.dart` so avatar and speech-speed controls are always visible.
- Kept only auxiliary panels (tips/challenge/stats) behind the compact toggle to preserve chat space without hiding core interaction controls.

New priorities discovered during testing

- Add a quick UI hint in compact mode clarifying exactly which panels are collapsed.

Blockers and decisions taken

- Decision: core session controls (avatar and speed) must never be hidden by default in compact behavior.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Top Area Simplification)

Completed items

- Removed high-vertical-cost panels from the top of `voice_chat_page.dart` (practice tip and daily challenge banner) to increase conversation space.

## Implementation Cycle Update (2026-03-07 - Session Scene Backgrounds)

Completed items

- Added persisted session scene support with `SessionScene` enum (`studio`, `city`, `library`) in domain layer.
- Added scene image assets and registration:
  - `assets/images/scenes/studio_scene.png`
  - `assets/images/scenes/city_scene.png`
  - `assets/images/scenes/library_scene.png`
- Extended session preferences persistence to store selected scene in local Hive repository.
- Added scene selector to `SessionSettingsPage` so users can choose visual context for the session.
- Applied selected scene as full-screen background in `VoiceChatPage` with dark overlay for text readability.
- Kept fallback gradient for resilience when image loading fails.

New priorities discovered during testing

- Stabilize `session_settings_page_test.dart`, which is timing out in widget test runtime despite controller persistence tests passing.
- Add a focused widget test for scene selection interaction (dropdown change + persisted restore) once the page test harness is stable.
- Optionally pre-cache selected scene image before opening chat to avoid first-frame pop-in on lower-end devices.

Blockers and decisions taken

- Decision: keep scene assets local and bundled (no network dependency) for offline reliability.
- Blocker: current widget test suite for session settings page is unstable (timeout); app-layer and controller-layer changes are validated.
- Moved speech-speed controls to a dedicated `AppBar` action (`speed` icon) that opens a bottom sheet picker.
- Kept avatar visible and reduced top clutter so message history occupies more usable height.

New priorities discovered during testing

- Consider a small one-time tooltip on the speed icon to help first-time users discover where speech speed is configured.

Blockers and decisions taken

- Decision: daily challenge remains available in Practice Hub instead of occupying vertical space in the live conversation surface.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Mobile Speech Rate Calibration)

Completed items

- Adjusted TTS rate mapping in `VoiceChatController` to use platform-aware base values:
  - Web keeps current base (`0.7`).
  - Mobile uses a lower base (`0.5`) to make `1.0x` sound natural.
- Kept multiplier options unchanged (`0.5x`, `1.0x`, `1.5x`, `2.0x`) while recalibrating the final engine rate.
- Updated and validated controller tests for the new calibrated numeric rates.

New priorities discovered during testing

- Add a tiny developer debug line (optional) showing effective engine rate (for example: `1.0x -> 0.5`) to accelerate device tuning.

Blockers and decisions taken

- Decision: treat web and mobile TTS speed curves differently because they do not map linearly to perceived speech speed.
- No blockers.

## Implementation Cycle Update (2026-03-07 - APK Build Fix Kotlin/JVM Target)

Completed items

- Fixed Android build failure caused by JVM target mismatch in plugin module compilation (`flutter_tts`: Java 17 vs Kotlin 1.8).
- Added global Kotlin compile task alignment in `android/build.gradle` to enforce `jvmTarget = 17` across subprojects/plugins.
- Re-ran release build and successfully generated split APKs.

Artifacts generated

- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

Blockers and decisions taken

- Decision: keep Java/Kotlin target centralized at Gradle root to avoid plugin-specific drift in future builds.
- No blockers.

Blockers and decisions taken

- Decision: keep clamp as `clamp(0.2, 1.0)` to preserve a usable slowest floor while allowing higher base-rate tuning.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Auto Mode Language Detection Fix)

Completed items

- Fixed root cause of error/fallback messages being returned in Portuguese when the user speaks English in `auto` mode.
- Root cause: in `auto` mode, language was inferred solely from which STT locale was tried first (alternating en/pt each turn), not from the actual text content. If Portuguese STT happened to be primary and returned a non-empty transcription of English speech, the entire turn was tagged as Portuguese.
- Added `_inferLanguageFromText()` method in `VoiceChatController` that performs lightweight keyword-based language detection on the captured text.
- Applied text-based language inference to all `_CapturedUserInput` return points in `auto` mode: primary capture, weak-capture fallback, secondary fallback, and `_pickBestAutoCapture`.
- The method uses common English and Portuguese marker words and only overrides the STT locale guess when the evidence is strong (at least 2 marker hits with clear majority).
- Non-auto modes (explicit `en-US` or `pt-BR`) are unaffected — they continue to use the user-selected language directly.

New priorities discovered during testing

- Add unit tests for `_inferLanguageFromText` covering mixed-language and edge-case inputs.
- Evaluate adding language-confidence from STT plugin if exposed in future package versions.
- Consider logging detected vs inferred language in debug mode to monitor real-device accuracy.

Blockers and decisions taken

- Decision: use a simple keyword-based heuristic rather than a full NLP library to keep the app lightweight and offline-capable.

## Implementation Cycle Update (2026-03-07 - Reading + Listening Learning Mode)

Completed items

- Added a new dedicated learning flow for guided reading and listening with short exercises and comprehension checks.
- Implemented domain model for reading/listening exercises in `lib/features/voice_chat/domain/entities/reading_listening_exercise.dart`.
- Implemented application layer components:
  - `ReadingListeningCatalog` with bilingual (`en-US`/`pt-BR`) exercise content.
  - `ReadingListeningController` for progression, answer validation, score summary, and persistence.
  - `LearningAudioService` interface for audio playback abstraction.
- Implemented infrastructure adapter `LearningAudioTtsService` to keep TTS integration isolated from UI/controller.
- Added new screen `ReadingListeningPage` with:
  - language selector (`English (US)` and `Portugues (BR)`),
  - audio playback controls,
  - multiple-choice comprehension flow,
  - end-of-session save action.
- Integrated navigation route `DashboardRoutes.readingListening` and entry points from:
  - dashboard quick menu,
  - practice overview,
  - practice hub modal opened from voice chat.
- Saved completed learning sessions into existing local history repository so they appear in progress/history metrics.
- Added unit tests in `reading_listening_controller_test.dart` validating progression, locale-aware audio playback, and single-save persistence behavior.

New priorities discovered during testing

- Add widget tests for `ReadingListeningPage` interaction states (option selection, disabled buttons, completion summary rendering).
- Add content expansion path (more exercises and level tags such as beginner/intermediate) while preserving bilingual parity.
- Consider optional STT shadow mode for read-aloud pronunciation checks in a future cycle.

Blockers and decisions taken

- Decision: first release of this feature focuses on listening comprehension + guided read-aloud without pronunciation scoring to keep latency low and implementation stable.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Reading/Listening Difficulty Levels)

Completed items

- Added difficulty metadata in reading/listening domain model with support for:
  - `beginner`
  - `intermediate`
- Added difficulty filter options in the new learning page (`All`, `Beginner`, `Intermediate`) with `en-US` and `pt-BR` labels.
- Updated `ReadingListeningController` to filter visible exercises by selected difficulty and drive progression over the filtered set.
- Implemented filter-change behavior that restarts the level session safely (index, answers, score, and completion state reset) to keep scoring consistent.
- Tagged catalog exercises by level in `ReadingListeningCatalog`.
- Extended controller tests to cover difficulty filtering and session reset behavior.

New priorities discovered during testing

- Add widget tests for difficulty-chip interactions and empty-state rendering when a level has no available content.
- Add optional adaptive recommendation (for example, suggest moving to intermediate after high beginner accuracy across sessions).

Blockers and decisions taken

- Decision: changing difficulty resets the current learning run to avoid mixed-level score distortion.
- No blockers.
- Decision: require at least 2 marker hits to override STT guess, avoiding false corrections on very short utterances.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Auto-Send + Edit-Resend Flow)

Completed items

- Redesigned review flow: STT-captured message is now sent immediately to the AI (no blocking gate).
- After the AI responds, a review panel appears showing the sent message as editable text.
- If the user edits and taps "Resend", the previous user+AI exchange is removed from conversation and the edited text is sent as a new request to the AI.
- A "Dismiss" button hides the review panel without changes if the user is satisfied.
- The review panel auto-dismisses when the next STT capture produces new input.
- Removed old completer-based blocking review mechanism, `isEditingPendingUserInputNotifier`, `beginPendingUserInputEditing()`, and `_PendingUserInputDecision` class.
- Updated all 3 review-related tests to match new auto-send + edit-resend behavior (25/25 passing).
- Simplified page UI: removed read-only TextField gate, pencil icon, and "must edit before send" hint.

New priorities discovered during testing

- Add widget test for edit-resend panel (dismiss + resend interaction).
- Validate that edit-resend during active STT capture doesn't cause double-turn regression on real devices.

Blockers and decisions taken

- Decision: the loop pauses temporarily during edit-resend to prevent race conditions with concurrent STT captures, then resumes automatically.
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

## Implementation Cycle Update (2026-03-07 - STT Read-Aloud Pronunciation Mode)

Completed items

- Added STT shadow read-aloud mode to reading/listening learning flow.
- New domain entity `PronunciationResult` and `PronunciationWordMatch` for word-level pronunciation feedback.
- New application-layer `PronunciationComparer` with Levenshtein-based fuzzy word matching for tolerating minor pronunciation differences.
- New `PronunciationCaptureService` interface and `SttPronunciationCaptureService` infrastructure adapter wrapping `SpeechService`.
- Updated `ReadingListeningController` with `startReadAloud()`, `clearPronunciationResult()`, and `canReadAloud` property.
- Updated `ReadingListeningPage` with "Read aloud" button next to "Listen" and visual pronunciation result panel showing per-word match status (green/red) and accuracy percentage.
- Added 6 unit tests for `PronunciationComparer` covering perfect match, partial match, empty input, punctuation handling, Levenshtein tolerance, and word match status.
- Added 2 unit tests for controller read-aloud behavior (successful capture + "no speech detected" error state).

New priorities discovered during testing

- Add widget test for read-aloud button and pronunciation result panel.
- Consider adding speech confidence scoring from STT plugin if exposed in future versions.

Blockers and decisions taken

- Decision: pronunciation capture is optional in the controller (nullable dependency) to preserve backward compatibility with tests and scenarios where STT is unavailable.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Session History Filter + Dedicated Page)

Completed items

- Added `SessionDateRange` enum (allTime, last7Days, last30Days) to `PracticeHubController`.
- Implemented date range filtering in `_refreshFilteredSessions()` alongside existing text search and focus filter.
- Added date range chips (All time / Last 7 days / Last 30 days) in `PracticeHubSheet` history card.
- Created dedicated `SessionHistoryPage` with full-page session browsing: search bar, date range chips, focus dropdown, and scrollable session list with detailed tiles (focus, date, duration, language, turns, feedback).
- Registered `/session-history` route in `DashboardRoutes` and `main.dart`.
- Added Session History entry to dashboard quick menu.

New priorities discovered during testing

- Add pagination or lazy loading for users with 50+ sessions.
- Add session detail tap to expand feedback text in full.

Blockers and decisions taken

- Decision: reuse `PracticeHubController` in the dedicated page to keep filter logic centralized.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Adaptive Difficulty, Content Expansion, and UX Polish)

Completed items

- Adaptive difficulty recommendation:
  - After saving a beginner learning session, the controller checks session history for past beginner runs.
  - If 2+ beginner sessions have ≥80% accuracy, `suggestIntermediateNotifier` activates.
  - Accuracy is parsed from the existing feedback string pattern (`(N%)`).
  - A prominent banner appears in the session summary card with a one-tap "Switch to Intermediate" action.
  - Fully bilingual recommendation text (`en-US` / `pt-BR`).

- Exercise catalogue expansion (+7 exercises):
  - Hotel check-in (beginner)
  - Grocery shopping (beginner)
  - Job interview (intermediate)
  - Weather chat (beginner)
  - Restaurant complaint (beginner)
  - Giving directions (beginner)
  - Rescheduling by phone (intermediate)
  - All exercises maintain full bilingual parity (titles, texts, questions, options).
  - Catalogue now has 12 total exercises (7 beginner, 5 intermediate).

- Auto-scroll to last message in chat:
  - Added `ScrollController` to the conversation `ListView` in `VoiceChatPage`.
  - After each conversation update, the list smoothly scrolls to the latest message.
  - Controller is properly disposed on page teardown.

- Pre-cache scene images:
  - Added `precacheImage` calls in `didChangeDependencies` for all `SessionScene` asset paths.
  - Eliminates first-frame background pop-in on slower devices.

- Validation:
  - All existing tests pass (31/31: reading_listening_controller 6/6, voice_chat_controller 25/25).
  - No compile errors across all changed files.

New priorities discovered during testing

- Add unit tests for adaptive difficulty recommendation logic (threshold boundary, parse accuracy edge cases).
- Add widget tests for the recommendation banner interaction (switch to intermediate action).
- Consider persisting the "already suggested" state to avoid showing the recommendation repeatedly after the user dismisses it.
- Add more intermediate-level exercises to balance the catalogue as users progress.

Blockers and decisions taken

- Decision: parse accuracy from feedback strings to keep the recommendation logic self-contained without adding new persistence fields to `PracticeSessionRecord`.
- Decision: recommendation resets when the user switches to intermediate, since the notifier is tied to the beginner filter state.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Streak/Consistency Banner on Dashboard)

Completed items

- Added `_StreakBanner` stateful widget to `InitialDashboardPage` that self-loads streak data from `SessionHistoryService`.
- Displays current streak count with fire icon (orange when 3+ days, white when less).
- Shows active days ratio (N/7) for the last week.
- Renders 7-day activity dots (green circles with check for active days, grey for inactive) with weekday labels.
- Weekday labels are bilingual (Mon-Sun / Seg-Dom) based on app locale.
- Banner appears prominently between the welcome card and the start session button.

New priorities discovered during testing

- Add animation or celebration effect when streak reaches milestone (3, 7, 14 days).
- Consider caching streak data to avoid repository read on every dashboard open.

Blockers and decisions taken

- Decision: streak banner loads its own data independently to keep `InitialDashboardPage` as a `StatelessWidget`.
- No blockers.
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

## Implementation Cycle Update (2026-03-07 - AI Provider/Model Settings)

Completed items

- Added AI configuration controls in `Session Settings` with local persistence:
  - provider select (`Gemini` or `OpenAI`)
  - model mode toggle (preset list or manual typing)
  - provider-specific model value (`geminiModel` and `openAiModel`)
- Extended `SessionUiPreferences` and Hive persistence keys to save/load AI provider and model choices.
- Updated runtime wiring so `VoiceChatPage` applies persisted AI settings before starting a session.
- Extended AI service constructors to accept model overrides while preserving `.env` defaults when settings are not customized.
- Added/updated automated tests for settings persistence and settings page rendering with AI preferences.

New priorities discovered during testing

- Add a visible status chip in `VoiceChatPage` showing active provider/model during the session for easier QA validation.
- Add a small validation hint for typed models (for example, known-prefix suggestion) to reduce invalid model typos.

Blockers and decisions taken

- Decision: keep API key sources in `.env` and only expose provider/model selection in UI for now.
- Decision: preserve provider-specific last model values so switching providers does not lose previous selection.
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

## Implementation Cycle Update (2026-03-07 - Gemini Model from Env)

Completed items

- Removed hardcoded Gemini model from `GeminiService` request URL.
- Added `geminiModel` resolution from environment variable `GEMINI_MODEL`.
- Added safe fallback to `gemini-2.5-flash` when `GEMINI_MODEL` is missing or empty.

New priorities discovered during testing

- Validate startup behavior with an intentionally invalid `GEMINI_MODEL` value to confirm API error mapping remains clear for troubleshooting.

Blockers and decisions taken

- Decision: keep `GEMINI_MODEL` centralized in `.env` for easier model switching without code changes.
- No blockers.

## Implementation Cycle Update (2026-03-07 - OpenAI Model from Env Resolver)

Completed items

- Applied the same model-resolution pattern in `OpenAIService` used by `GeminiService`.
- Replaced direct `OPENAI_MODEL` property read with `_resolveOpenAiModel()`.
- Added safe fallback to `gpt-4.1` when `OPENAI_MODEL` is missing or empty.

New priorities discovered during testing

- Consider unifying provider model resolution in a shared helper to avoid duplicated env parsing logic.

Blockers and decisions taken

- Decision: keep provider-specific fallback defaults (`gpt-4.1` for OpenAI and `gemini-2.5-flash` for Gemini) to preserve backward-compatible behavior.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Auto Language PT-BR Recognition)

Completed items

- Improved `VoiceChatController` auto-listening strategy so `en_US` non-empty capture is no longer accepted blindly when language signal is weak.
- Added language-hint scoring (`en` vs `pt`) to:
  - decide when `auto` should still try `pt_BR` after `en_US`
  - choose the best transcript between English and Portuguese candidates
  - detect response language with better continuity in ambiguous turns (fallback to last detected language on ties)
- Preserved explicit language mode behavior (`English (US)` and `Portugues (BR)`) unchanged.
- Added/updated controller tests for:
  - existing empty `en_US` fallback path
  - weak-English non-empty result that should prefer Portuguese transcript
  - strong-English path that should remain in English
- Re-ran `voice_chat_controller_test.dart` with all tests passing (`22 passed, 0 failed`).

New priorities discovered during testing

- Add integration-level STT tests with realistic bilingual phrases to fine-tune hint scoring thresholds.
- Consider exposing a tiny debug indicator (dev mode only) showing which transcript (`en_US` or `pt_BR`) was chosen in auto mode.

Blockers and decisions taken

- Decision: keep scoring heuristics lightweight and local to application layer (no plugin API changes), minimizing risk while improving bilingual auto behavior.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Auto Language PT-BR Tuning v2)

Completed items

- Tightened `auto` fallback trigger in `VoiceChatController`:
  - English candidate is now accepted only when it has a stronger confidence signal.
  - Ambiguous short/weak English recognition now triggers `pt_BR` retry more often.
- Improved transcript selection tie-break logic in auto mode by preferring richer Portuguese candidate when both fits are similar.
- Expanded language hints with additional conversational tokens (`oi`, `bom dia`, `boa tarde`, `boa noite`, `good afternoon`, etc.) for better real-world phrase coverage.
- Preserved command stability by treating known short English commands (`speed up`, `slow down`, `normal speed`, `repeat`) as strong English signals to avoid unnecessary fallback.
- Re-ran controller tests successfully after tuning (`22 passed, 0 failed`).

New priorities discovered during testing

- Add end-to-end device validation checklist for auto-language mode with fixed bilingual phrase set to monitor false-English and false-Portuguese rates.
- Consider exposing a hidden diagnostics label in debug mode showing scoring outcome (`enScore`, `ptScore`) for faster tuning.

Blockers and decisions taken

- Decision: keep fallback tuning in application layer heuristics first, avoiding infrastructure/plugin changes in this cycle.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Auto Mode Deterministic PT Priority)

Completed items

- Replaced auto-mode hint-based language inference in `VoiceChatController` with deterministic STT locale capture flow.
- Auto mode now prioritizes `pt_BR` capture first and falls back to `en_US` only when Portuguese capture is empty.
- Conversation language in auto mode now uses the locale that actually captured speech, instead of post-transcription hint guessing.
- Removed auto-mode text hint scoring methods (`_detectLanguage`, `_scoreLanguageHints`, and related fallback heuristics) to avoid false-English misclassification on Portuguese speech.
- Updated language-mode UI copy to reflect real behavior (`Portuguese first`, then English fallback).
- Updated controller tests to validate new behavior and kept English-command tests stable by explicitly forcing `English (US)` mode where expected.
- Re-ran voice-chat controller test suite with full pass (`22 passed, 0 failed`).

New priorities discovered during testing

- Add an explicit product setting to choose auto priority order (`PT first` or `EN first`) for user-controlled behavior.
- Add real-device smoke checklist for Portuguese colloquial commands (for example: `repete por favor`, `fala de novo`, `pode repetir`).

Blockers and decisions taken

- Decision: prioritize user reliability in Portuguese auto mode over previous English-first behavior to resolve repeated real-world recognition failures.
- No blockers.

## Implementation Cycle Update (2026-03-07 - Auto Mixed-Language + TTS Voice Quality)

Completed items

- Refined `auto` listening behavior in `VoiceChatController` to better support mixed Portuguese/English turns:
  - auto mode now alternates primary STT locale between `pt_BR` and `en_US` each turn (instead of getting stuck in one language path)
  - when the primary capture looks weak (very short transcript), controller performs secondary-locale fallback and prefers the richer candidate
  - kept explicit language modes (`English (US)` / `Portugues (BR)`) unchanged
- Improved `TTSService` voice quality strategy:
  - added dynamic voice catalog loading via `flutter_tts.getVoices`
  - added best-voice selection per locale (`en-US`, `pt-BR`) with preference for higher-quality voice names (`neural`, `network`, `wavenet`, `natural`, etc.)
  - kept safe fallback to engine default voice if no better voice is available
- Validation:
  - `voice_chat_controller_test.dart` + `speech_service_test.dart` run completed successfully (`25 passed, 0 failed`)

New priorities discovered during testing

- Add in-app voice selector in settings so users can choose preferred installed voice directly per locale.
- Add optional debug status showing selected TTS voice name at runtime for device-level troubleshooting.

Blockers and decisions taken

- Decision: keep TTS voice improvement non-breaking by auto-selecting better voices when available and falling back silently when not.
- No blockers.
