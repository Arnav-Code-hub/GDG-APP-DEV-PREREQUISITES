# QuizOrbit — project reference and decision log

**Updated:** 2026-11-01 (Asia/Calcutta)  
**Current phase:** Phases 1–4 implemented. Play Store “worth installing” feature set implemented (topics, 203-question bank, daily challenge, stats, timer, sharing, reporting, settings, intro, Hindi UI, review prompt). Live Firebase project connected; Google provider still to be enabled. Phase 5 (device verification, release) remains.  
**Quality target:** Production-quality presentation; a prototype under development is not a production-verified app.

This is the current project reference. It supersedes the older draft in `docs/superpowers/plans/2026-10-29-quiz-app.md`. Keep the decisions, phases, and verification here current as work proceeds.

## 1. Goal and prerequisite requirements

Build a polished mobile quiz app for a second-year student applying to the App Development domain, with engineering the student can explain.

**Assignment source:** `C:/Users/ARNAV_TFS/Downloads/Responsibilities and Pre-Interview Tasks 26-27.pdf`, page 5, “App Development → Second & Third Year.”

The assignment requires:

- A mobile app in Flutter (preferred), Java, or Kotlin.
- At least two quiz categories.
- Multiple-choice questions and a final score.
- Advanced OOP, data modeling, state management, and UI/business-logic separation.
- Optional: SQLite or Firebase storage of questions or previous scores.

Firebase is required for this project because the user selected it. The assignment itself does not prescribe a question count, login provider, timer, leaderboard, APK submission, repository, or demo video for this domain. Recommendations below are not extra assignment requirements.

## 2. Confirmed user decisions

- **Stack:** Flutter with Dart, and Firebase for storage.
- **Categories:** Anime and Sports. These replace the original programming/computer-science suggestions.
- **Saved data:** Only completed quizzes for the signed-in account. Unfinished/abandoned attempts create no quiz record in Firebase.
- **Visual reference:** [Unbelievably Crap](https://www.unbelievablycrap.com/), adapted for a mobile quiz rather than copied as a desktop portfolio.
- **Motion direction:** Focused adaptation. Stronger effects on Categories and Results, restrained motion and stationary answer controls during questions.
- **Quality:** The prototype must look production-ready and have complete, intentional interface details: consistent styling, finished copy, responsive layout, accessible controls, proper states, and no dead controls or fabricated account/statistics data.
- **Execution:** Create this reference, update the earlier plan, and implement Phase 1 now. Later phases are planned, not already implemented.
- **Maintenance:** Record future meaningful decisions here in simple but detailed language.
- **Landing refinement:** The user accepted the Phase 1 UI and requested animation on its text and ring. Preserve the established visual design while adding that motion now.
- **Further refinement:** The user requested stronger headline copy/animation and an overall UI improvement. This authorizes polishing the landing layout and presentation, while keeping Anime/Sports, the dark visual direction, and existing motion-accessibility behavior.
- **Sign-in provider (2026-11-01):** Google sign-in.
- **Review past attempts (2026-11-01):** A player finishes the quiz first; only then is the attempt stored, and the player can review it later. This settles the earlier open schema question: completed records include the answers (question IDs + chosen option indices). It also adds a history screen, which §3 previously listed as not requested.
- **Play Store feature set (2026-11-01):** Implement a bigger question pool with random 10 per attempt served from Firestore, personal stats, a daily challenge with an opt-in reminder, sub-categories, a shareable result card, “report this question”, an optional timer, haptics and sound, a two-screen intro, Hindi localization and a Play In-App Review prompt. Follow-up instruction: do not build a vast question set; finish quickly.
- **UI v2 (2026-11-01):** Improve the UI/UX with ui-ux-pro-max, make the prototype presentation-ready, keep the same black/red color theme, take inspiration from a supplied dark mobile UI reference (rounded layered cards, pill buttons and chips, lit primary button, grabber sheets, round icon buttons, avatar header), then use Hallmark to fix the improved UI.

## 3. Implementation defaults

These are engineering choices/proposals, not claims that the user explicitly specified every detail.

- **Working name:** QuizOrbit, introduced in the earlier Spline prompt; provisional until the user chooses a name.
- **Quiz size:** Ten questions per attempt, drawn from a pool of 100+ per category (203 total, six topics of 30–40). Four choices, one correct. *(Supersedes the fixed ten-per-category bank.)*
- **Scoring:** One point/correct answer, zero otherwise, no negative marking. Show the final count out of the total, such as 7/10.
- **Flow (user confirmed 2026-11-01, supersedes per-question Submit/feedback):** Answer every question first; answers can be changed (Previous, untimed mode) until **Submit quiz**, which asks for confirmation. Nothing is marked right or wrong before then. Results then reveal the score, each answer, its explanation and “Report this question”. Timed mode: a question locks when you move on or its 20 s run out (unanswered = no answer) and the quiz advances; no going back.
- **Retry/discard:** Retry clears score, selections, feedback, and progress. Ask before discarding an unfinished attempt.
- **Questions:** Bundled JSON at `assets/questions/questions.json` (version `2026-11-01.1`), validated on load. The loader rejects any category that does not have exactly ten four-option questions, so the category sheet's “10 questions / 4 choices” text is guaranteed by the data rather than hard-coded hope.
- **Feedback color:** One added semantic token, `OrbitColors.correct` (#5BD68A), for correct-answer feedback. It always appears with text (“Correct answer”, “CORRECT.”) and an icon, never as color alone, and passes the 4.5:1 contrast test on both surfaces.
- **Attempt state:** Unfinished attempts stay in memory; no resume after process death is promised.
- **Screens:** Categories → Quiz → Results, plus Your attempts → Attempt review for signed-in players. Account actions live in an avatar menu in the landing masthead; Results offers “Sign in to save” for a result finished while signed out.
- **State tools:** Flutter SDK `ChangeNotifier`/`ListenableBuilder`; no additional state-management package selected.
- **Frontend technology:** Reproduce React/Framer Motion-style effects using Flutter animation APIs. Motion for React cannot animate Flutter widgets directly; React is not part of this mobile frontend.
- **Depth:** Original wireframe orbital geometry rendered with Flutter CustomPainter. The landing refinement rotates a cached ring layer; its guide grid, markers, and captions stay fixed. No geometry recalculation on each animation frame, shader, downloaded artwork, or Spline runtime is required.
- **Fonts:** Bundle Barlow body text and Barlow Condensed headings with their OFL licences, shown in-app under Open-source licences (IBM Plex Mono was dropped when labels moved to Barlow); no runtime font service or font dependency.
- **Dependencies:** `firebase_core`, `firebase_auth` and `cloud_firestore` only. Google sign-in goes through `firebase_auth` (`signInWithPopup` on web, `signInWithProvider` on Android), so no separate Google sign-in package. Rules tests use `@firebase/rules-unit-testing` + `firebase` as Node dev dependencies in `rules_test/`, outside the app.
- **Not requested:** Timer, leaderboard, social features, or admin panel. (A history screen was later requested — see §2.) Production-quality presentation is not authorization to add unrelated features.

## 4. How the app fulfills the prerequisite

### Mobile functionality

Flutter/Dart meets the preferred framework choice. Anime and Sports meet the two-category minimum. Playable multiple-choice quizzes and a Results screen with the correct final score fulfill the functional requirements when implemented. Phase 1's category preview alone is not evidence of a playable quiz.

### Data modeling

Use immutable models rather than disconnected variables:

- `QuizCategory`: stable category ID and display name.
- `Question`: stable ID, category ID, prompt, choices, correct-choice index, explanation.
- `QuizResult`: category, correct count, total count, and completed-attempt identity when saving exists.

Validate loaded questions: unique IDs, known categories, nonempty text, distinct valid choices, and an in-range correct index. Never identify correctness by matching displayed answer text.

### State management and separation of concerns

- **Screens:** Display state and forward actions. No score calculation or direct mutation of answer collections.
- **Quiz controller:** Owns the current question, selection, submitted answers, progression, score, and reset behavior.
- **Question repository:** Loads and validates question data outside widgets.
- **Completed-attempt repository:** Saves completed attempts outside widgets once persistence exists.

Animations observe presentation state. Animation completion/cancellation must never score an answer or trigger database writes.

### OOP evidence

- **Encapsulation:** Private mutable attempt state, controlled public actions, read-only access.
- **Composition:** Screens/controllers receive their dependencies instead of embedding all responsibilities.
- **Abstraction/polymorphism:** Repository contracts allow a real data source in the app and an in-memory implementation in tests.

The PDF does not define “advanced OOP” precisely. Explain these actual engineering boundaries during the interview; do not create unnecessary subclasses just to display terminology.

### Database enhancement

Firebase completed-attempt storage covers the assignment's optional storage enhancement. Claim verified storage compliance only after account ownership, saves, retries, and rules are implemented and tested. Styling and 3D effects improve presentation but do not replace engineering requirements.

## 5. Visual and interaction direction

- Near-black surfaces, off-white text, charcoal structural dividers, red accents.
- Bold condensed headings, readable body/question text, monospace technical labels.
- Numbered category panels, thin framing lines, clear hierarchy, and an original geometric/question-mark emblem.
- Faint static grain/scanlines behind decoration, not across questions or answer text.
- Categories can be expressive. Quiz questions/targets remain stable. Results combines the real score, navigation, and truthful saving status once implemented.
- Respect safe areas, allow scrolling, adapt gutters, bound large-screen content width, and prevent clipping on small/landscape screens.
- Use at least 48 logical pixels for Android touch targets, sufficient contrast, labeled controls, sensible semantics/focus order, and scalable text.
- Phase 1 category details are functional previews; no account, save, or start-quiz control may pretend its unimplemented behavior works.

Motion timing (source of truth: `OrbitMotion` in `lib/foundation/theme.dart`): **800 ms** landing headline entrance (implemented; supersedes the earlier 500 ms stagger), **350 ms** category entry route fade/rise (implemented), **200 ms** question fade-in with no movement (implemented), **120 ms** selection color feedback (implemented), **600 ms** Results score count-up (implemented). Accessibility receives the actual score from the first frame; only the visible digits animate. All of these become instant under reduced motion.

Use `AnimationController`, `Transform`, `AnimatedSwitcher`, and Flutter route transitions. Reduced motion removes decorative tilt, glitch, and movement. Landing text/ring animation is brought forward as a user-requested Phase 1 refinement; quiz/result choreography remains Phase 4.

### Landing animation refinement

- *(Superseded by the headline refinement below: the entrance is now 800 ms with clipped 28 px line reveals.)* Originally: reveal the eyebrow, headline, and supporting copy in a staggered **500 ms** entrance with eased opacity and **16 logical pixels** of upward travel. Play once per landing hero mount; opening/closing category details must not replay it. Keep layout space reserved and heading semantics available immediately.
- Rotate only the wireframe ring slowly, **one full turn per 24 seconds**, about its painted center. Preserve the grid/captions, original colors, typography, panels, and overall layout.
- Give the decorative loop a labeled, keyboard/screen-reader accessible **Pause/Play** control with a minimum 48×48 target. Manual pause stays in effect across resize, backgrounding, and category sheets.
- Stop ring ticks when it is offscreen, the app is inactive, its route is covered, or TickerMode is disabled; resume from the same angle when eligible. Isolate static painter layers with RepaintBoundary.
- Honor both Android Remove animations and iOS Reduce Motion, including runtime preference changes. In reduced motion, show settled text and a still ring, with no animation control needed. Returning to normal motion must not replay the heading.
- No new runtime dependencies. Test repeating motion with bounded frame advances; run foundation settle-based checks under reduced motion so a decorative loop cannot cause test timeouts.

### Headline and landing UI refinement (implemented and verified 2026-11-01)

- **Copy choice:** Replace “BEYOND THE OBVIOUS.” with **“KNOW IT? PROVE IT.”** The question/challenge communicates the purpose of a fandom quiz more directly. This is an implementation choice under the user's copy-improvement request, not wording dictated by the assignment.
- **Text animation:** Use an **800 ms** coordinated entrance, revealing the two headline lines in sequence with clipping, opacity, and **28 px** of upward travel. Supporting text keeps a smaller 16 px entrance. Keep a single accessible heading name available immediately; reduced motion shows every line settled. This supersedes the earlier 500 ms whole-heading treatment.
- **Real primary action:** Add “Choose your category” near the headline. It scrolls to the category section over 350 ms (immediately under reduced motion), then focuses Anime so keyboard users can activate it without searching the page. Each category sheet now has a working “Start {category} quiz” action (the earlier “coming soon” preview label was removed when gameplay became real).
- **Layout:** Simplify header/footer copy, shorten category descriptions, give each card its own visible Explore action, and retain equal desktop panel heights. Keep the ring's state stable across layout changes, with a smaller maximum width on phones.
- **Artwork:** Add original static vector anime-energy and sports-court/ball marks. Decorations neither intercept input nor enter the accessibility tree; omit them at large text sizes to prioritize the category text. No third-party images, copyright characters, or new dependency is required.
- **Feedback:** Category buttons use native pressed behavior and explicit hover/focus surfaces/borders. Target sizes, text scaling, reduced motion, truthful coming-soon previews, and the existing ring guards remain requirements.

## 6. Five implementation phases

### Phase 1 — Visual foundation (complete)

- Create the theme, typography, semantic colors, spacing, and component tokens.
- Build reusable buttons, numbered/category panels, and progress presentation.
- Build an original depth emblem and faint static texture.
- Assemble a polished responsive Anime/Sports Categories/sample screen with working category details and honest scope.
- Verify representative phone/landscape/large-screen layouts, enlarged text, accessibility, and feedback.

**Exit:** A running visual foundation with usable sample interactions, consistent styling, no overflow at tested sizes, and recorded test/visual evidence. Authentication, real quizzes, and Firebase are outside Phase 1.

### Phase 2 — Three screens and their states (implemented)

- Build Categories, Quiz, Results from the foundation.
- Include loading, empty, error/retry, selected/submitted answer, and result states with finished copy.
- Verify layout, safe areas, text scaling, and touch targets throughout.

**Exit:** All screen states are demonstrable; quiz behavior/persistence is not declared complete until Phase 3.

**Status:** Quiz and Results screens implemented with loading, empty, error/retry, unselected/selected/submitted, correct/incorrect text feedback, progress, score, all five save states, discard confirmation, retry and exit. Account/sign-in UI waits for the provider decision.

### Phase 3 — Quiz behavior and account persistence (local engine implemented; Firebase blocked)

- Author/verify Anime and Sports questions; implement models and data validation.
- Implement/test selection, submit locking, progression, score, completion, retry, and discard in the controller.
- Resolve database/auth/recovery decisions below; implement authenticated Firebase storage for completed attempts only.
- Add truthful saving feedback, duplicate-safe retries, ownership rules, and emulator security tests.

**Exit:** Both categories work end to end, scores are correct, saves belong to the correct account, unfinished attempts are not stored, and retries do not create duplicates.

**Status:** Implemented: question bank, models, validation, controller, Google sign-in (`FirebaseAccountSession`), `FirestoreAttemptRepository` (save + history), `firestore.rules`, and 15 rules tests in `rules_test/`. Unit/widget tests cover the app side with in-memory implementations. **Not done:** connecting a real Firebase project (`flutterfire configure`), Google provider/SHA-1 setup, running the rules tests (blocked: firebase-tools 15 requires JDK 21, installed JDK is 17), and any live-cloud verification.

### Phase 4 — Motion and effects (partially implemented)

- Extend the implemented landing motion language to category entry, question/selection, and score transitions. Landing text/ring motion was brought forward by the user's refinement request.
- Add restrained tilt/RGB accents while keeping answer targets stationary.
- Support reduced motion, dispose animation resources, and keep animation separate from quiz/database logic.

**Exit:** The reference's character is present, controls remain readable/responsive, and interrupted motion cannot alter app correctness.

**Status:** All five planned timings are implemented (see §5). A test taps answers 50 ms into each question fade and confirms the score is unchanged. Results now has a soft red radial glow behind the score; RGB-split accents were not added (they would conflict with the softer v2 direction).

### Phase 5 — Verification and interview preparation (planned)

- Run analysis and the complete test suite; exercise invalid data, rapid taps, interrupted transitions, retries, switching, discard, and save failures.
- Check accessibility, representative screen sizes, landscape, enlarged text, and reduced motion.
- Profile on physical Android hardware; build/install an APK and prepare screenshots, README, and a short engineering demo.

**Exit:** The installed app meets the assignment with evidence and documented limitations. Store release, production signing, deployment, and operations require separate work.

## 6a. Code map (what to explain in the interview)

| Concern | File | OOP point |
|---|---|---|
| Immutable data | `lib/quiz/models.dart` | `QuizCategory` (stable `id`), `Question`, `AnswerRecord`, `QuizResult`; unmodifiable lists; correctness by index |
| Data loading + validation | `lib/quiz/question_repository.dart` | `QuestionRepository` interface; `AssetQuestionRepository` (app) vs `FakeQuestionRepository` (tests) — polymorphism |
| Quiz state + scoring | `lib/quiz/quiz_controller.dart` | `ChangeNotifier`; private state, guarded `select/submit/next/finish/reset`; idempotent `finish` creates the attempt ID once |
| Saving | `lib/quiz/attempt_repository.dart` | `CompletedAttemptRepository` interface; `AttemptSaver` captures the owner at completion and retries with the same ID |
| Account | `lib/account/account_session.dart`, `lib/firebase/firebase_account_session.dart` | `AccountSession` interface; Firebase Google sign-in (app) vs `FakeAccountSession` (tests) |
| Firebase wiring | `lib/firebase/bootstrap.dart`, `lib/firebase/firestore_attempt_repository.dart`, `firestore.rules` | Starts Firebase only when configured; record mapping and validation; owner-only rules |
| History | `lib/quiz/history_screen.dart`, `lib/quiz/answer_review.dart` | `SavedAttempt.review` matches stored answers back to questions; shared review list |
| Screens | `lib/quiz/quiz_screen.dart`, `lib/quiz/results_view.dart`, `lib/home/category_home.dart` | Widgets only display state and forward actions; dependencies injected from `MainApp` (composition) |

Landing-only copy (numbers, descriptions) is an extension in the home screen, so presentation text does not leak into the data model.

## 7. Firebase contract

**Live project (created 2026-11-01 at the user's request):** `quizorbit-gdg-26` (display name QuizOrbit), owned by the Firebase CLI account the user was logged in with. `flutterfire configure` registered a web app and an Android app (`dev.quizorbit.quiz_orbit`), generated `lib/firebase_options.dart` and `android/app/google-services.json`, and added the Google Services Gradle plugin. Firestore API enabled; `firestore.rules` compiled and released. Firestore database `(default)` is in **asia-south1 (Mumbai)**. The first deploy had auto-created it in nam5 (an ordering mistake); at the user's request the empty nam5 database was deleted and recreated in asia-south1, and the rules were deployed to it again.

**Verified live:** the release web build initializes Firebase against this project at `http://localhost:5183` with no console errors and shows Google sign-in. **Not verified live:** sign-in (Google provider not yet enabled — console step), any Firestore write/read, Android.

**Implemented (code):**

- **Database:** Cloud Firestore, `users/{uid}/attempts/{attemptId}`. Record: `categoryId`, `score`, `total`, `questionSetVersion`, `completedAt`, `questionIds`, `selectedIndices`. Written once, when the player presses “See your score” on the last submitted question. Nothing is written for unfinished or discarded quizzes.
- **Identity:** Firebase Authentication with Google. The owner is captured when the quiz finishes; signing out or switching accounts cannot redirect a pending/retried save. A result finished while signed out can be saved by signing in from Results.
- **Duplicates:** the attempt ID is created once in `finish()`; saves use `set` on that ID. Rules allow a repeat write only if identical to the stored record, so retries are harmless and records cannot be edited or deleted.
- **Truthful states:** Saving… → Saved only after Firestore acknowledges; Couldn’t save after an error or 15 s timeout, with Retry; Not saved when signed out or Firebase is not configured.
- **Rules (`firestore.rules`):** owner-only read/create; no update except identical retry; no delete; everything else closed; shape checks (exact keys, known category, `total == 10`, integer score 0–total, list lengths, timestamp within −1 day/+5 min of server time).
- **History:** newest 100 attempts; unreadable records are skipped, not fatal; questions removed from the bank show “no longer in the quiz” in the review.
- **Startup:** `lib/firebase_options.dart` is a placeholder until `flutterfire configure` replaces it. Without it, the app runs fully but cannot sign in or save, and says so. `--dart-define=USE_FIREBASE_EMULATORS=true` uses a local `demo-quizorbit` emulator project instead.

**Known limits (documented, not hidden):** client-computed scores are not authoritative; rules check shape, not honesty. A write still queued offline for more than a day is rejected by the timestamp rule. No process-death recovery for an unsaved result.

**Still needs the user:** enable Authentication → Google in the console (and pick a support email); add the Android debug SHA-1 for Google sign-in on Android; JDK 21 for the emulator rules tests. Firebase Auth authorizes `localhost` by default, not `127.0.0.1`, so test web sign-in at `http://localhost:5183`.

## 8. Verification and current limitations

- Work is on `codex/phase-1-foundation` in the supplied workspace. The repository began without commits; no seed commit or worktree creation was needed.
- Installed tooling: Flutter 3.47.2 and Dart 3.13.2. Flutter Doctor reports missing Android command-line tools and unknown license status; no connected phone/emulator is available.
- Phase 1 was checked with Flutter tests, web build, and browser inspection. These checks must not be presented as Android runtime/APK success.
- No live authentication, full quiz engine, verified question bank, Firebase integration, deployment, release, physical-device profiling, or production security review is currently claimed.
- The earlier 12–20-hour estimate was for a simpler quiz core; it does not establish a total for Firebase and the selected design.

### Phase 1 implementation and verification record — 2026-11-01

- **Implemented:** Flutter Android scaffold plus web preview; dark semantic theme, spacing/motion tokens, Barlow/Barlow Condensed/IBM Plex Mono typography, shared buttons/panels/progress, static original 3D-projected wireframe emblem, and responsive Anime/Sports landing screen.
- **Implemented:** Both Explore actions open matching, scrollable category-preview sheets with close/back controls. The sheets explicitly label the quiz as coming soon and the question counts as planned format. They do not claim gameplay or storage already works.
- **Implemented:** Original launcher/favicon artwork and dark platform startup styling replace generated Flutter branding. No runtime packages beyond Flutter were added.
- **Verified:** `flutter test` passes **11 tests**. Coverage includes both category previews; 320×640 and 375×812 phones, 844×390 landscape and 1440×1000 desktop at 2× text with reduced animations; scrolling to the preview's bottom control; Android target sizes; control labels; direct screen-reader activation; keyboard open/Escape dismissal; category reading groups; progress semantics; and text-color contrast.
- **Verified:** Blank-scaffold category tests failed before implementation. Removing the semantic activation callback made the regression fail; restoring it passed. The category-grouping test also failed before semantic groups were added.
- **Visual review:** Inspected desktop and portrait browser layouts, corrected header/footer divider widths and matched desktop panel heights. Browser inspection exposed interleaved category reading order, so each panel now has an explicit semantic group.
- **Review:** A separate reviewer checked the Phase 1 Dart code/tests. Its preview-label concern and activation/reachability test gaps were addressed. This review is not physical-device or backend verification.
- **Verified:** Final `flutter analyze` reports no issues; final `flutter build web --no-web-resources-cdn --no-wasm-dry-run` exits successfully. The earlier build also passed the optional Wasm dry-run. Dart formatting check passes for all six source/test files.
- **Build note:** Flutter emits a non-fatal tree-shaking warning about an optional Cupertino icon font. This Android/Material foundation uses Material icons; no Cupertino package was added just to silence the warning. Apple platform icon behavior is not verified.
- **Verified:** Refreshed final desktop/mobile browser previews, opened Sports details and returned to Categories, and inspected grouped accessibility output. Screenshots: [desktop](docs/previews/phase-1-desktop.jpg), [mobile](docs/previews/phase-1-mobile.jpg), [category preview](docs/previews/phase-1-category-preview.jpg).
- **Preview:** The local review build is served at `http://127.0.0.1:5183` while this session's HTTP server is running. For an independently started development preview use `flutter run -d chrome`; the README contains commands.
- **Not verified:** Android compilation/installation, physical-device performance, native TalkBack/VoiceOver, or real Firebase behavior. Android resource XML/JSON/icon checks are not substitutes for Android compilation.

### Landing motion refinement — 2026-11-01

- **Implemented:** Three staggered 500 ms text reveals with opacity/16 px travel; settled semantics are available immediately. No layout-space animation, new dependency, or replay on category dismissal.
- **Implemented:** 24-second ring rotation uses a static isolated geometry layer. The diagram's guide grid/markers and captions do not rotate. Pause/Play is a native, labeled control; manual pause is preserved across the mobile/desktop breakpoint.
- **Implemented:** Android/iOS reduced-motion preferences, runtime changes, application lifecycle, route coverage, TickerMode, and scroll visibility stop the loop when appropriate. Controller and scroll/binding listeners are disposed.
- **Verified:** `flutter test` passes **23 tests**: the original 11 foundation checks plus 12 motion checks covering one-shot entrance/layout stability; actual rotation, pause/resume and disposal; separate Android/iOS reduction signals; runtime preference changes; offscreen resume; background/manual-pause behavior; breakpoint persistence; active-motion control semantics/48 px targets at 2× text on a 320 px phone; keyboard Space activation; category-sheet suspension; and TickerMode phase preservation.
- **Verified:** Motion tests failed against the static landing page before implementation. A new resize regression reproduced pause loss before the single-Flex hero layout fixed it. Final `flutter analyze` reports no issues.
- **Verified:** Final release web build succeeds (`flutter build web --no-web-resources-cdn --no-wasm-dry-run`), analysis reports no issues, and all nine Dart source/test files pass the formatting check. The previously recorded optional Cupertino font warning remains non-fatal.
- **Visual review:** Refreshed the live browser preview, observed ring rotation while the diagram guides/captions stayed fixed, used Pause, and resized to phone width without losing the paused state. Restored the active animation and normal browser viewport afterward. [Refreshed preview](docs/previews/landing-motion.jpg).
- **Not verified:** Native physical-device performance, native TalkBack/VoiceOver, and iOS hardware preference changes. Tests exercise Flutter accessibility signals and semantic actions, not the physical assistive-technology software.

### Phases 2–4 implementation and verification record — 2026-11-01

- **Re-checked baseline before editing:** headline refinement code (800 ms, two clipped line reveals, “KNOW IT? PROVE IT.”, Choose-your-category scroll/focus) was already complete. `flutter test` passed **25 tests** (not 23: the two landing-refinement tests had been added), analysis clean, formatting clean. The newest screenshot still showed the old “BEYOND THE OBVIOUS.” build; the refreshed browser check below replaces it.
- **Implemented:** models, 20-question bank, validation, repository, controller, save contract/`AttemptSaver`, Quiz and Results screens, category-sheet Start action, `OrbitOutlinedButton` (shared by cards, sheet, quiz and results), `OrbitProgress.current`, `OrbitPanel.borderColor`.
- **Fixed during verification:** (Moderate) the loading row overflowed by 38 px at 320 px wide with 2× text — caught by the new layout test, fixed with `Flexible`. (Moderate) on phones the answer explanation appeared below the fold after Submit, so users could tap Next without seeing it; feedback now scrolls itself into view once, after answers are locked, so no tap target moves under a finger. A layout test asserts it is on screen at 320×640/2× text; this assertion was added after the fix and was not run against the old code.
- **Verified:** `flutter test` passes **63 tests** (25 existing + 27 logic + 11 widget-flow). Logic tests cover all-right/all-wrong/mixed scores; no submit without selection; locked answers; double submit/next; last-question bounds; idempotent finish; reset; category isolation; immutable lists; distinct IDs; 12 malformed-data cases; the real bundled file; saved-only-after-acknowledgement; failed save keeps result and retries with the same ID; pending write stays with its original account; signed-out/unavailable states. Flow tests cover landing→sheet→quiz→score; discard dialog via close and system back with zero writes; failed→retry save; Try again creates a second record; load error→retry; rapid double tap on Next; taps mid-fade; 320×640 and 844×390 at 2× text with Android tap-target/label guidelines.
- **Verified:** `flutter analyze` no issues; `dart format` clean; `flutter build web --no-web-resources-cdn --no-wasm-dry-run` succeeds (same non-fatal Cupertino font warning).
- **Browser check (release web build at http://127.0.0.1:5183, 375×812):** headline settles correctly; Choose-your-category scrolls and focuses Anime; Start opens the quiz; wrong-answer state shows YOUR ANSWER/CORRECT ANSWER text and icons. A full Anime run driven through Flutter's web accessibility tree (semantic button activation) scored **9/10** with one deliberate wrong answer; the review listed “You chose A. Ryuk / Answer: D. Kira”, and the save panel said NOT SAVED. Screenshots: [landing](docs/previews/landing-headline-mobile.jpg), [quiz feedback](docs/previews/quiz-feedback-mobile.jpg) (captured before the feedback auto-scroll fix).
- **Not verified:** Android compile/install, physical devices, native TalkBack/VoiceOver, any Firebase behavior.

### UI v2, Google sign-in and history — 2026-11-01

- **ui-ux-pro-max:** used for targeted stack/UX queries (Flutter semantics, touch targets, loading feedback). Its search script fails under Python isolated mode (`-I`) because it imports a sibling module; it was run normally. No design system was regenerated over the existing one.
- **Design changes:** radius scale (16 controls, 24 cards, 28 sheets); pill primary button with a red glow token; pill secondary buttons on a raised surface; round raised icon buttons; filter chips with counts; grabber bottom sheets; rounded option tiles with letter discs; layered score card with a soft red radial glow; tinted stat badges; quieter `hairline` card edges; Barlow Condensed Bold for button text (only Regular Barlow is bundled, so no synthesized bold).
- **Hallmark:** its `sloplint` checks HTML/CSS and cannot read a Flutter canvas, so the `audit` procedure was applied manually to rendered screens (`docs/previews/v2/`). Applied floor rules: sentence-case untracked labels (was tracked caps), eyebrow removed (its words moved into the hero sentence), no middle-dot meta strings, tokens only, focus visible immediately, reduced-motion fallbacks, no invented metrics, no card inside a card. Findings fixed after the first render: (Moderate) signed-in masthead wrapped and used a square button → avatar menu; (Moderate) display-only stat chips looked tappable → compact tinted badges; (Nitpick) primary glow read as a dark rim → dedicated glow token.
- **Verified:** `flutter test` **73 passing** (adds history, record round-trip/validation, account sign-in/cancel/failure, owner-binding, sign-in-to-save tests). `flutter analyze` clean, format clean, release web build succeeds. Previews rendered from widget tests with the bundled fonts at 390×844: [v2 previews](docs/previews/v2/).
- **Not verified:** rules tests (written, not run: JDK 21 needed), any live Firebase call, Google sign-in on a real device or browser, Android build. The browser pane's emulated phone viewport cropped screenshots, so v2 screenshots come from widget-test renders, not the browser.

### Play Store feature set — 2026-11-01

**What was built**

| Feature | How | Where |
|---|---|---|
| Bigger pool, random 10 | 203 fact-checked questions in six topics; `QuizPicker.practice` draws 10; “Try again” draws a fresh set | `tool/question_source.py` → `tool/build_questions.py` → `assets/questions/questions.json`; `lib/quiz/quiz_picker.dart` |
| Served from Firestore | `LayeredQuestionRepository` uses `questionBanks/current` when valid and not older than the bundled bank, else the bundled bank; download never blocks play | `lib/firebase/firestore_content.dart`, `tool/publish_questions.mjs` |
| Sub-categories | Topics in the data (Shōnen, Studio Ghibli, Anime icons; Cricket, Football, Olympic sports); topic chips in the category sheet | `lib/quiz/question_repository.dart`, `lib/home/category_home.dart` |
| Daily challenge | Same 10 per category per local day for everyone (FNV-1a + Mulberry32 seeded shuffle, identical on Android and web); attempt ID `daily-<category>-<yyyymmdd>` so the rules allow one stored go; landing shows Play / Done + review | `quiz_picker.dart`, `firestore.rules`, `category_home.dart` |
| Daily reminder | Opt-in, inexact daily local notification (no exact-alarm permission); Android only, hidden on web | `lib/app/device_services.dart`, `AndroidManifest.xml` |
| Personal stats | Streak (alive until a whole day is missed), best streak, accuracy, per-category best/average, last-10 chart with spoken summary — all from the player’s own saved attempts | `lib/quiz/stats.dart`, `lib/quiz/stats_screen.dart` |
| Timer mode | Optional, 20 s/question; a plain `Timer` that pauses in the background; expiry calls `QuizController.timeOut()`, stored as index −1 and reviewed as “Time ran out” | `quiz_controller.dart`, `quiz_screen.dart` |
| Share card | The on-screen score card is rendered to PNG and passed to the share sheet with a caption | `results_view.dart`, `lib/app/result_sharer.dart` |
| Report a question | Reason chips + optional note (≤300); signed-in only; create-only `questionReports` (nobody can read them from the app) | `lib/quiz/report_sheet.dart`, `firestore.rules` |
| Haptics and sound | Selection click, correct/wrong haptics; two original synthesized tones; each behind a setting | `device_services.dart`, `assets/sounds/` |
| Settings | Sound, vibration, reminder, language (device / English / हिन्दी), replay intro, open-source licences | `lib/app/settings_screen.dart`, `lib/app/settings.dart` |
| First-run intro | Two skippable pages, shown once | `lib/app/intro_screen.dart` |
| Hindi | All interface text via `gen-l10n` (`lib/l10n/app_en.arb`, `app_hi.arb`); questions stay English (stated in Settings) | `lib/l10n/` |
| In-App Review | Android only; score ≥ 8, ≥ 3 finished quizzes, at most once per 60 days (Play also rate-limits) | `device_services.dart` |

**Architecture change:** screens now read an immutable `AppServices` bundle from an `AppScope` InheritedWidget instead of receiving each dependency through constructors. Still constructor-style injection through the tree (tests build their own `AppServices` with fakes), not a global locator. Practice picking is injectable so tests can play a known order.

**Schema/rules change (deployed to `quizorbit-gdg-26`):** attempts gain `topicId`, `mode`, `timed`; practice IDs stay random 20-char, daily IDs are date-fixed; `questionBanks/*` public-read, no client writes; `questionReports/*` create-only with owner, reason enum, note ≤300, server timestamp. Older records without the new fields read as untimed practice.

**Bugs found and fixed during this work:** (Moderate) three “Try again”/refresh handlers passed a Future-returning closure to `setState`, which throws — the History error retry, the quiz load retry and the daily refresh would have crashed; caught by widget tests. (Moderate) cards were plain `DecoratedBox`es, so list-tile ink inside them was invisible; `OrbitPanel` is now a `Material` surface. (Nitpick) explicit `INTERNET` permission added to the main Android manifest rather than relying on Firebase’s merged manifest. Also: reading `AppScope` after an `await` in the quiz loader (fixed by capturing first).

**Verified:** `flutter analyze` clean; `dart format` clean; **91 tests pass** (73 earlier + 18 new: picker determinism and distinctness, daily ID, topic validation, layered remote fallback, legacy record reading, timeout logic and a 20-second timed-mode widget test, daily once-a-day flow with fixed ID and “Done today” state, streak/accuracy maths, report flow and signed-out prompt, share image + caption, feedback events, intro, Hindi switch with persisted settings, review-prompt rules). Release web build succeeds and starts against the live project with no console errors (intro → landing with daily card checked in the browser). Updated rules compiled and deployed.

**Not verified:** rules tests (15 cases written, need JDK 21); Android build, notifications, haptics, sound and In-App Review on a device (no Android SDK/device here); real Google sign-in (provider not yet enabled); the Firestore-published bank (needs admin credentials for `tool/publish_questions.mjs` — until published, the bundled bank is used); Hindi glyphs fall back to system fonts because the bundled fonts are Latin-only; question facts were checked by the author, not by an external reviewer.

### Submit-at-end flow, Hallmark clean-up, ambient background — 2026-11-01

- **Quiz flow (implemented):** `QuizController` no longer has per-question Submit. Answers live in one list and stay changeable until `finish()`; `previous()` in untimed mode; timed questions lock on Next or timeout. Pinned bar: Previous (icon) + one primary action (Choose an answer → Next question → Submit quiz with a confirmation dialog). Per-answer feedback, the instant explanation panel and per-answer sounds were removed; the explanation and Report moved to the Results review cards; one haptic/sound plays on submit.
- **Hallmark audit (implemented):** labels moved from IBM Plex Mono to Barlow (gate 64); no coloured glow on the primary button and no radial halo behind the score (29); eyebrows removed: card ordinals, “Category 01”, “Anime final score” above the figure (now a caption after it) (54); “Fig. 01, an open mind” and the “Q.01” counter removed (66/69); stat tiles no longer stack an icon over the figure (3); masthead hairline removed (42); daily-challenge buttons are secondary so one red primary leads each view (23); display line-height 0.88 → 1.02 for wrapping caps (55a); no stock arrow on every button (63). **Waived on the record:** the white/red two-line hero headline is the brand signature, used once (38iii); the wireframe ring is the app’s geometric material, not an illustration (80).
- **Ambient background (implemented):** `lib/foundation/ambient_background.dart` — a faint dot-matrix field with a slow travelling ripple and an occasional soft red sweep, echoing the dot-matrix figures in the user’s reference image. Chosen over drifting colour blobs because Hallmark gate 29 flags those. Never takes input, excluded from semantics, still under reduced motion, ~20 fps, stops with TickerMode (offstage routes, background), one shared clock so it does not jump between screens, dimmed to 60 % behind quiz questions.
- **Colour review (ui-ux-pro-max, not implemented):** its palette search returned stock framework swatches (blue/violet), which Hallmark 74 rejects, so recommendations stay within the black/red identity: warm-tint the neutrals (hue ~25), give answer outlines 3:1 contrast (today 1.22:1), split brand red from an “incorrect” crimson, cap red at ~8 % of a screen, and an optional light “paper” mode from the reference (red darkened to #BF2E19 for 5:1). Shown to the user as an image; awaiting a decision.
- **Ponytail review → fixed (user asked):**
  - (Moderate) Daily challenge saved from two devices looped on “Couldn’t save”; a rejected daily write now checks for today’s record and shows **Already played today** (new `SaveStatus.alreadyPlayed`, no retry). Test added; the test fake now refuses to overwrite a stored attempt, like the rules.
  - (Moderate) Report spam: reports now use the fixed ID `{uid}_{questionId}` and the rules allow create-once, so a player can report each question once (a repeat counts as already sent). Rules deployed. *Shortcut noted in code:* caps spam per account, not scripted accounts; App Check is still a launch item.
  - (Moderate) The daily card started its data load inside `build()`; it now loads from `didChangeDependencies` and an account listener that reloads only when the player changes.
  - (Moderate) `MainApp` duplicated all ten `AppServices` fields; it now takes `AppServices` directly (`main.dart` 102 lines). Tests use the shared `testServices` helper.
  - (Nitpick) Removed 10 unused strings, the unused IBM Plex Mono font and its notice, `QuizController.reset()` and its test (retry already builds a fresh controller; covered by the “try again” widget test); the background painter reuses its point buffers.
  - **Found while fixing:** the fonts’ OFL notices were never shipped or registered, so Settings › Open-source licences omitted them. Barlow and Barlow Condensed notices are now bundled and registered at startup.
- **Palette preview:** the landing page rendered from the real app in current, proposed dark and light “paper” palettes, with only colour tokens swapped (source restored): [docs/previews/palette-proposal.png](docs/previews/palette-proposal.png). Not implemented.
- **Verified:** `flutter analyze` clean, format clean, **95 tests pass** (controller rewritten for the new flow; widget tests for no reveal before submit, Previous changing an answer, the submit dialog returning to answers, timed auto-advance; two ambient-background tests: still under reduced motion, stops when tickers are off). Release web build succeeds. Visual check from widget-test renders. After the ponytail fixes: analyze clean, format clean, 95 tests pass (+1 daily already-played, −1 removed `reset` test), release web build succeeds, updated rules deployed. **Not redeployed** to Hosting; the live site still runs the previous version. Rules tests still not run (JDK 21).

## 9. Decision log and maintenance rule

For every meaningful product/design/architecture/data/dependency/verification change, update the relevant section and add a dated log entry with the decision, reason, status, and any superseded choice. Use plain language. Record consequential decisions, not every editing action.

Labels: **User confirmed**, **Implementation default**, **Open**, **Implemented**, **Verified**. Implemented does not imply verified. Do not turn proposals into user-approved requirements or backdate future decisions.

- **2026-11-01 — User confirmed:** Flutter/Dart and Firebase. Reason: selected stack; replaces backend-free recommendation.
- **2026-11-01 — User confirmed:** Save completed quizzes for their account only. Replaces the open question about unfinished/per-answer saves.
- **2026-11-01 — User confirmed:** Anime and Sports. Replaces the programming/computer-science suggestions.
- **2026-11-01 — User confirmed:** Focused reference adaptation. Reason: user selected stronger Categories/Results motion with readable, stable quiz controls.
- **2026-11-01 — Implementation default:** Flutter-native effects instead of React/Framer Motion. Reason: compatibility with the selected mobile frontend.
- **2026-11-01 — Implementation default:** Ten questions/category, four choices, one point/correct answer, provisional QuizOrbit name. Reason: coherent small demonstration; these details are proposals, not explicit user requirements.
- **2026-11-01 — User confirmed:** Production-quality presentation despite prototype status. Reason: latest quality instruction; no fabricated functionality or unrelated features.
- **2026-11-01 — User confirmed:** Create/maintain `quiz.md`, update the older plan, and implement Phase 1. This reference supersedes the old draft.
- **2026-11-01 — Implementation default:** Use current workspace on `codex/phase-1-foundation`; no worktree seed commit. Reason: initially empty repository and user-requested root reference location; no push/deployment implied.
- **2026-11-01 — Implementation default:** Bundle Barlow Condensed/IBM Plex Mono and OFL notices; Flutter-only runtime dependencies for Phase 1. Reason: intentional editorial type without a runtime font network request or extra package.
- **2026-11-01 — Open:** Firestore confirmation, sign-in provider, detailed-response schema, offline-save recovery, and Firebase environment. These do not block visual foundation work.
- **2026-11-01 — Implemented:** Visual foundation uses native Flutter widgets and static projected orbital geometry. Reason: retain the reference's technical/depth aesthetic without a WebView, 3D engine, external art, or continuous redraw; animated effects remain Phase 4.
- **2026-11-01 — Implemented:** Barlow is also bundled for body text, alongside the two earlier font choices. Reason: keep longer copy readable and avoid default-font network downloads. All three OFL notices are included.
- **2026-11-01 — Implemented:** Category sheets clearly distinguish previews/planned format from playable quizzes. Reason: production-quality presentation must not fabricate completed functionality.
- **2026-11-01 — Verified:** Eleven foundation tests pass, including direct assistive-technology activation and keyboard controls. Reason: labels and screenshots alone do not demonstrate accessible interaction.
- **2026-11-01 — Verified:** Phase 1 exit conditions met through passing tests, analysis, release web compilation, and refreshed browser review. Phase 2 remains planned; polished presentation does not imply a complete quiz engine or production release.
- **2026-11-01 — User confirmed:** Phase 1 UI accepted; add landing text and ring animations now. This brings only landing motion forward from Phase 4; quiz/results/backend scope is unchanged.
- **2026-11-01 — Implementation default, now implemented:** 500 ms/16 px staggered text entrance plus 24-second cached ring rotation, Pause/Play, reduced-motion support, and visibility/lifecycle guards. Reason: add the requested motion while keeping the approved layout, readable copy, and bounded rendering work. Verification is recorded above.
- **2026-11-01 — Implemented:** A stable Flex/Flexible hero hierarchy preserves manual ring pause when crossing the 800 px breakpoint. Reason: responsive resizing must not silently re-enable paused decoration; verified by a failing-then-passing regression.
- **2026-11-01 — Verified:** 23 total tests and clean analysis after landing motion. Foundation settle-based tests intentionally use reduced motion; separate bounded-frame tests verify the actual animated UI and its new controls.
- **2026-11-01 — Verified:** Release web compilation and browser motion/pause/responsive checks completed; screenshot saved. No additional runtime dependency, backend feature, quiz behavior, or native-release claim was introduced.
- **2026-11-01 — User confirmed, installed:** Install Hallmark and Graphify from the supplied repositories. Both are registered as user-wide Codex skills; Graphify also has its isolated Python CLI. These are development tools, not Flutter runtime dependencies, and installation does not authorize a UI redesign or project indexing run.
- **2026-11-01 — User confirmed:** Improve headline copy, animate the text more noticeably, and improve the overall landing UI using ui-ux-pro-max. No new quiz/backend scope was requested.
- **2026-11-01 — Implementation choice, in progress:** “KNOW IT? PROVE IT.”, 800 ms line reveals, category-scroll/focus action, simpler metadata, original category marks, shorter copy, and native button focus/hover feedback. Reason: communicate the quiz's job and put a useful action within reach on a phone while retaining the established style.

- **2026-11-01 — Verified:** Headline refinement (“KNOW IT? PROVE IT.”, 800 ms clipped line reveals, scroll-and-focus action) is complete; tests pass and the release web build was checked in the browser. Status changed from in progress to verified.
- **2026-11-01 — Implementation default, implemented:** Bundled JSON questions, `QuizCategory` moved from the home screen into `lib/quiz/models.dart` with stable IDs; landing copy kept as a home-screen extension. Reason: the quiz data model should not carry landing-page prose.
- **2026-11-01 — Implementation default, implemented:** Validation enforces exactly 10 questions × 4 options per category. Reason: the UI states that format, so the data must guarantee it; malformed data shows an error state with retry.
- **2026-11-01 — Implementation default, implemented:** Attempt ID is a 20-character secure-random ID created once in `QuizController.finish()`; retries of a save reuse it, Try again produces a new one. Reason: duplicate-safe Firestore `set` without a server round trip.
- **2026-11-01 — Implementation default, implemented:** The owner is captured when `AttemptSaver` is created, not read at write time. Reason: a sign-out or account switch during a pending save must not move the record to another account.
- **2026-11-01 — Implementation default, implemented:** Quiz flow uses a single route; Results replaces the question view in place and Try again calls `reset()`. Reason: system back from Results needs no discard prompt, and retry cannot leak state from a previous route.
- **2026-11-01 — Implementation default, implemented:** One pinned primary action (Choose an answer → Submit answer → Next question / See your score) in a fixed bottom bar. Reason: the main control never moves between states.
- **2026-11-01 — Implementation default, implemented:** Added `OrbitColors.correct` and the shared `OrbitOutlinedButton`. Reason: a semantic success color was missing; the outlined style was duplicated inline.
- **2026-11-01 — Superseded:** the open list above. Sign-in provider and per-answer records are now user-confirmed; Firestore is an implementation default nobody objected to; the Firebase project and offline recovery remain open.
- **2026-11-01 — User confirmed:** Google sign-in.
- **2026-11-01 — User confirmed:** Store an attempt only after it is completed, and let the player review it. Implemented as per-answer records plus History and Review screens.
- **2026-11-01 — User confirmed, implemented:** UI v2 from the supplied reference in the existing colors, then a Hallmark audit. Reason: presentation-ready prototype. Supersedes the square-cornered editorial controls and tracked-caps labels; the black/red palette, fonts, headline, ring and motion rules stay.
- **2026-11-01 — Implementation default:** Firebase starts only when real options exist; the placeholder `firebase_options.dart` keeps the app runnable and truthful. Reason: no project exists yet and no fake backend may be labelled Firebase.
- **2026-11-01 — Implementation default:** Identical-retry-only updates and no deletes in rules. Reason: duplicate-safe retries without letting a client edit a saved score.
- **2026-11-01 — User confirmed, done:** Create a new Firebase project. Created `quizorbit-gdg-26`, registered web + Android apps, deployed rules. Firestore landed in nam5 instead of the intended asia-south1 (see §7).
- **2026-11-01 — User confirmed, done:** Move Firestore to asia-south1 (Mumbai). Reason: lower latency for players in India; the location cannot be changed later, so it was fixed while the database was still empty.
- **2026-11-01 — User confirmed, implemented:** The “High” and “Nice to have” Play Store features. Implementation defaults: one daily challenge per category per local day; Hindi covers UI text only; six topics; 20 s timer; review prompt thresholds above; reports create-only. The user asked not to grow the question set further; 203 questions is final for now.
- **2026-11-01 — Superseded:** “Not requested: timer” (§3) and the fixed ten-question bank — both now requested and implemented.
- **2026-11-01 — User confirmed, done:** Host the web app on Firebase. Deployed `build/web` to Firebase Hosting at https://quizorbit-gdg-26.web.app with an SPA rewrite. Verified: site loads with no console errors; root, deep links and `main.dart.js` return 200 with `Cache-Control: no-cache`. Implementation default: no-cache on every file, because Flutter web file names are not content-hashed (a first config cached `/` and `main.dart.js` for an hour, which could mix versions after a redeploy; fixed before handing over).
- **2026-11-01 — User confirmed, implemented:** Answer all questions, then submit, then see the score (supersedes instant per-question feedback).
- **2026-11-01 — User confirmed, implemented:** Hallmark pass to remove AI-tell elements; a soft but active background (implemented as a dot-matrix field, not blobs, per Hallmark 29).
- **2026-11-01 — User confirmed, pending approval:** Colour recommendations (image shown, not implemented) and a revamp plan from the reference image (plan shown, not implemented).
- **2026-11-01 — User confirmed, done:** On screens under 520 px the account control shows the avatar only and the full name heads its menu, so the name is never cut off (it rendered as "Ar…" on phones). Verified by tests at 390 px and at 320 px with 2x text (97 tests pass), a rendered check ([docs/previews/masthead-phone.png](docs/previews/masthead-phone.png)), and redeployed to Hosting.
- **2026-11-01 — Open:** Google provider enablement (console), publishing the bank (admin credentials), JDK 21 for rules tests, Android device verification, process-death recovery, the “Critical” launch items (account deletion, privacy policy, release signing, App Check, Crashlytics).

## 10. Installed development tools

- **Hallmark 2.0.0:** Installed from [nutlope/hallmark](https://github.com/nutlope/hallmark) into `C:/Users/ARNAV_TFS/.codex/skills/hallmark` using the bundled Codex skill installer. Its design references, scripts, agent guidance, and license were copied. Node 24.11.1 is available. Verification: reference checker reports clean across 101 files; static linter help runs. Optional rendered browser audits were not exercised.
- **Graphify 0.9.100:** Installed the repository's official `graphifyy` PyPI package into the isolated environment `C:/Users/ARNAV_TFS/.codex/tools/graphify`, using Python 3.13.7. Registered the Codex skill via `python -X utf8 -m graphify install --platform codex`, with references under `C:/Users/ARNAV_TFS/.codex/skills/graphify`. A UTF-8 launcher at `C:/Users/ARNAV_TFS/.local/bin/graphify.cmd` uses the existing user PATH; no PATH edit was necessary. Source: [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify).
- **Verified:** `graphify --version` reports 0.9.100 and its isolated environment passes `pip check`. The installer retained restrictive temporary-directory permissions on its public reference folder; restoring normal parent ACL inheritance made those references readable by the sandboxed agent. No permissions on app data or other folders were changed.
- **Scope:** Skills become available on the next turn. Invoke Hallmark or Graphify by name. No optional always-on project hooks, AGENTS.md changes, cloud account, indexing run, or Flutter dependency was added. Existing UI decisions remain in force.

### Graphify project map — 2026-11-01

- **User requested, generated:** A local project map in `graphify-out/`, covering 65 source/configuration/test files and three Markdown documents. Screenshots, decorative assets, font licences and sound files were excluded from semantic analysis. Unsupported file types such as `firestore.rules` are not structurally parsed; the storage contract is also documented in this reference.
- **Scope and limits:** Graphify explains file, symbol and documented design relationships. Its Dart extraction uses heuristics; generated localization symbols can dominate connectivity. This map does not verify app execution, live Firebase, security rules or Android behavior. No runtime dependency or app behavior changed. Graph artifacts are not currently ignored by Git.

## References

### Source repository — 2026-11-01

- **User confirmed:** Push the complete project to a repository named “GDG-APP-DEV PREREQUISITES”. The GitHub-compatible name is `GDG-APP-DEV-PREREQUISITES`.
- **Created:** [Arnav-Code-hub/GDG-APP-DEV-PREREQUISITES](https://github.com/Arnav-Code-hub/GDG-APP-DEV-PREREQUISITES), private by default, with `main` as the repository branch.
- **Scope:** Commit the app source, tests, fonts/art/sounds, question bank, Firebase client configuration and rules, developer scripts, screenshots, and project documentation. Exclude dependencies, builds, temporary files, generated Graphify caches, local credentials, and signing keys through `.gitignore`. Firebase client configuration is part of the app; privileged credentials are not.
- **Verified before commit:** `flutter test --no-pub` passes **97 tests**; `flutter analyze --no-pub` reports no issues. Source was scanned for private-key/token patterns without printing credential values; none were found.
- **Boundary:** This operation publishes the source snapshot only. It does not redeploy Hosting, change Firebase rules/providers, enable unfinished release features, or establish native-device verification.

- Assignment: `C:/Users/ARNAV_TFS/Downloads/Responsibilities and Pre-Interview Tasks 26-27.pdf`, page 5.
- Design: https://www.unbelievablycrap.com/
- Flutter architecture: https://docs.flutter.dev/app-architecture/guide
- Flutter animation: https://docs.flutter.dev/ui/animations/staggered-animations
- Flutter performance: https://docs.flutter.dev/perf/best-practices
- Firebase rules: https://firebase.google.com/docs/rules
