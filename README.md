# QuizOrbit

Source repository: [GDG-APP-DEV-PREREQUISITES](https://github.com/Arnav-Code-hub/GDG-APP-DEV-PREREQUISITES) (private).

A Flutter/Dart quiz app in development for the second-year App Development prerequisite. The categories are **Anime** and **Sports**. The visual direction is a mobile adaptation of the dark editorial styling at [Unbelievably Crap](https://www.unbelievablycrap.com/), using original artwork and native Flutter widgets.

**Current scope:** Anime and Sports quizzes with 203 questions across six topics; each attempt draws ten. Pick a topic, optionally turn on a 20-second timer, answer, and get a score you can share as an image. A daily challenge gives everyone the same ten questions each day. Signed-in players (Google) save completed attempts, review every answer, see stats and streaks, and can report a bad question. Settings cover sound, vibration, a daily reminder (Android) and English/Hindi.

**Status:** connected to Firebase project `quizorbit-gdg-26` (Firestore in asia-south1, rules deployed). Google sign-in must still be enabled in the console. Android has not been built or run here.

The complete requirements, five phases, decisions, and verification record live in [quiz.md](quiz.md). Production-quality presentation is the target; production operational readiness is not claimed.

The landing text now reveals once on entry and the wireframe ring rotates slowly. Pause/Play controls the decorative loop. Reduced-motion settings show the settled text and a still ring; offscreen, inactive, and covered views stop ticking. The approved visual design is retained.

## Run

Development tooling: **Flutter 3.47.2 / Dart 3.13.2**.

```sh
flutter pub get
flutter run -d chrome
```

To run on a connected Android emulator/device after completing Android SDK setup:

```sh
flutter run
```

The inspected local environment has missing Android command-line tools, unknown Android license status, and no connected Android device. Use `flutter doctor -v` to check your environment; browser verification does not establish Android runtime or APK success.

## Check and build

```sh
flutter analyze
flutter test
flutter build web --no-web-resources-cdn --no-wasm-dry-run
```

The web build is written to `build/web`. Serve it through an HTTP server rather than opening `index.html` directly. The build command bundles Flutter web rendering resources instead of depending on the rendering-resource CDN. Test/build outcomes and remaining verification limits are recorded in `quiz.md`; the commands above are instructions, not a claim they have passed.

## Live web app

Hosted on Firebase Hosting: **https://quizorbit-gdg-26.web.app**

To redeploy after changes:

```sh
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
firebase deploy --only hosting --project quizorbit-gdg-26
```

Every file is served `no-cache` (revalidated by ETag) because Flutter web file names are not content-hashed; this prevents a returning visitor mixing old and new files after a deploy.

## Connect Firebase (one-time, needs your Google account)

1. Create or choose a Firebase project in the Firebase console.
2. Enable **Authentication → Google** and create a **Cloud Firestore** database.
3. From this folder: `dart pub global activate flutterfire_cli`, then `flutterfire configure` (pick the project, Android and Web). This replaces the placeholder `lib/firebase_options.dart`.
4. For Google sign-in on Android, add your debug SHA-1 to the Android app in project settings.
5. Deploy the rules: `firebase deploy --only firestore:rules --project <project-id>`.

### Local emulator instead of a real project

Requires JDK 21+ (firebase-tools 15 refuses older Java).

```sh
firebase emulators:start --only auth,firestore --project demo-quizorbit
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
```

### Publish new questions (optional)

Edit `tool/question_source.py`, run `python tool/build_questions.py`, then with admin credentials (`gcloud auth application-default login` or `GOOGLE_APPLICATION_CREDENTIALS`):

```sh
cd tool
npm install
npm run publish -- --project quizorbit-gdg-26
```

Players get the published bank on next launch; the app falls back to its bundled bank if the download is missing, invalid or older.

### Rules tests

```sh
cd rules_test
npm install
npm test
```

## Architecture

- `lib/quiz/models.dart` — immutable `QuizCategory`, `Question`, `AnswerRecord`, `QuizResult`.
- `lib/quiz/question_repository.dart` — loads and validates `assets/questions/questions.json`.
- `lib/quiz/quiz_controller.dart` — all quiz state, scoring and guarded actions (`ChangeNotifier`).
- `lib/quiz/attempt_repository.dart` — completed-attempt storage contract and save-state tracking.
- `lib/quiz/quiz_screen.dart`, `lib/quiz/results_view.dart`, `lib/quiz/history_screen.dart` — UI only; dependencies are injected from `MainApp`.
- `lib/account/` and `lib/firebase/` — Google sign-in and Firestore storage behind small interfaces, so tests use in-memory versions.
- `firestore.rules` — owner-only access; saved attempts cannot be edited or deleted.

Only **completed** attempts will be saved, under the account that finished them. Unfinished attempts are never written.

Firebase database product, sign-in provider, completed-attempt detail schema, and offline-save recovery remain open decisions. No Firebase project configuration or credentials are included.

## Assets

The orbital launcher/favicon artwork is original, code-native vector geometry. Platform icon PNGs are generated from the same original geometry.

Barlow body text, Barlow Condensed headings, and IBM Plex Mono labels are bundled locally so typography does not need a font-service network request. Their SIL Open Font License notices are included alongside the font files in `assets/fonts/`.
