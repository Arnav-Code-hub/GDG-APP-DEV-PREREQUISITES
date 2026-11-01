// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuizOrbit';

  @override
  String get categoryAnime => 'Anime';

  @override
  String get categorySports => 'Sports';

  @override
  String get heroLineOne => 'KNOW IT?';

  @override
  String get heroLineTwo => 'PROVE IT.';

  @override
  String get heroSemantic => 'Know it? Prove it.';

  @override
  String get heroBody =>
      'Anime worlds. Sporting moments.\nA quiz for the fans who know.';

  @override
  String get chooseCategoryAction => 'Choose your category';

  @override
  String get chooseCategoryHeading => 'Choose your category.';

  @override
  String get categorySectionNote => 'Over 100 questions in each.';

  @override
  String get animeDescription =>
      'Characters, worlds, and stories you never forget.';

  @override
  String get sportsDescription =>
      'Rules, rivalries, and moments that made the game.';

  @override
  String get animeDetail =>
      'Characters, worlds, and the stories that stay with you.';

  @override
  String get sportsDetail =>
      'Rules, rivalries, and the moments that define the game.';

  @override
  String exploreCategory(String category) {
    return 'Explore $category';
  }

  @override
  String categoryGroupLabel(String category) {
    return '$category category';
  }

  @override
  String get footerTagline => 'A quiz for curious fans.';

  @override
  String get ringPause => 'Pause';

  @override
  String get ringPlay => 'Play';

  @override
  String get ringPauseTooltip => 'Pause ring animation';

  @override
  String get ringResumeTooltip => 'Resume ring animation';

  @override
  String get dailyHeading => 'Today’s challenge';

  @override
  String get dailyBody =>
      'The same 10 questions for every player today. One go each.';

  @override
  String dailyPlay(String category) {
    return 'Play today’s $category';
  }

  @override
  String dailyDone(int score, int total) {
    return 'Done today: $score/$total';
  }

  @override
  String get dailySignInNote =>
      'Sign in to save your daily result and keep your streak.';

  @override
  String get closeCategory => 'Close category details';

  @override
  String inFocus(String category) {
    return '$category, in focus.';
  }

  @override
  String get howItWorks => 'How it works';

  @override
  String questionsCount(int count) {
    return '$count questions';
  }

  @override
  String choicesPerQuestion(int count) {
    return '$count choices per question';
  }

  @override
  String get onePointRule => 'One point for every correct answer.';

  @override
  String get topicLabel => 'Topic';

  @override
  String get allTopics => 'All topics';

  @override
  String get timedMode => 'Timed mode';

  @override
  String timedModeHint(int seconds) {
    return '$seconds seconds per question';
  }

  @override
  String startQuiz(String category) {
    return 'Start $category quiz';
  }

  @override
  String get backToCategories => 'Back to categories';

  @override
  String quizTitle(String category) {
    return '$category quiz';
  }

  @override
  String dailyQuizTitle(String category) {
    return 'Daily $category';
  }

  @override
  String get leaveQuiz => 'Leave quiz';

  @override
  String questionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get progressLabel => 'Quiz progress';

  @override
  String progressValue(int completed, int total) {
    return '$completed of $total questions completed';
  }

  @override
  String questionSemantic(int number, int total, String prompt) {
    return 'Question $number of $total. $prompt';
  }

  @override
  String get chooseAnswer => 'Choose an answer';

  @override
  String get nextQuestion => 'Next question';

  @override
  String secondsLeft(int seconds) {
    return '${seconds}s';
  }

  @override
  String secondsLeftSemantic(int seconds) {
    return '$seconds seconds left';
  }

  @override
  String get leaveTitle => 'Leave this quiz?';

  @override
  String get leaveBody =>
      'Your answers so far will be discarded. Only finished quizzes count.';

  @override
  String get keepPlaying => 'Keep playing';

  @override
  String get discardAndLeave => 'Discard and leave';

  @override
  String get loadingQuestions => 'Loading questions…';

  @override
  String get noQuestions => 'No questions';

  @override
  String get somethingWrong => 'Something went wrong';

  @override
  String get quizEmpty => 'This quiz is empty.';

  @override
  String get questionsDidntLoad => 'Questions didn’t load.';

  @override
  String get quizEmptyBody =>
      'There are no questions for this category yet. Try another category.';

  @override
  String get questionsErrorBody =>
      'The question set couldn’t be read. Try again, or choose another category.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get reportQuestion => 'Report this question';

  @override
  String get reportTitle => 'Report a problem';

  @override
  String get reportWrong => 'The answer is wrong';

  @override
  String get reportUnclear => 'The question is unclear';

  @override
  String get reportTypo => 'Spelling or typo';

  @override
  String get reportOther => 'Something else';

  @override
  String get reportNote => 'Anything to add? (optional)';

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSending => 'Sending…';

  @override
  String get reportSent => 'Thanks. We’ll check this question.';

  @override
  String get reportFailed => 'Couldn’t send the report. Try again.';

  @override
  String get reportSignIn => 'Sign in to report a question.';

  @override
  String get reportUnavailable => 'Reporting isn’t connected in this build.';

  @override
  String finalScore(String category) {
    return '$category final score';
  }

  @override
  String get verdictPerfect => 'Proved it.';

  @override
  String get verdictGreat => 'You know it.';

  @override
  String get verdictOkay => 'Getting there.';

  @override
  String get verdictLow => 'Room to grow.';

  @override
  String get correctChip => 'Correct';

  @override
  String get missedChip => 'Missed';

  @override
  String scoreSemantic(int score, int total) {
    return 'Score: $score out of $total';
  }

  @override
  String get notSaved => 'Not saved';

  @override
  String get unavailableBody =>
      'Account saving isn’t connected in this build yet. Your score is shown here only.';

  @override
  String get signedOutBody =>
      'You weren’t signed in when you finished. Sign in with Google to save this result to your account.';

  @override
  String get saving => 'Saving…';

  @override
  String get savingBody => 'Saving this result to your account.';

  @override
  String get saved => 'Saved';

  @override
  String get savedBody =>
      'This result is saved to your account. You can review it any time.';

  @override
  String get couldntSave => 'Couldn’t save';

  @override
  String get failedBody =>
      'Your score is safe on this screen. Check your connection and try again.';

  @override
  String get retrySave => 'Retry save';

  @override
  String get signInToSave => 'Sign in to save';

  @override
  String get seeAllAttempts => 'See all your attempts';

  @override
  String get chooseAnotherCategory => 'Choose another category';

  @override
  String get yourAnswers => 'Your answers';

  @override
  String get shareResult => 'Share result';

  @override
  String shareText(int score, int total, String category) {
    return 'I scored $score/$total in $category on QuizOrbit. Know it? Prove it.';
  }

  @override
  String get shareFailed => 'Couldn’t share the result.';

  @override
  String get dailyComeBack =>
      'That was today’s challenge. A new one is ready tomorrow.';

  @override
  String get playPractice => 'Play a practice quiz';

  @override
  String questionNumber(int number) {
    return 'Question $number';
  }

  @override
  String get noLongerInQuiz => 'This question is no longer in the quiz.';

  @override
  String correctOption(String option) {
    return 'Correct: $option';
  }

  @override
  String youChose(String option) {
    return 'You chose $option';
  }

  @override
  String answerOption(String option) {
    return 'Answer: $option';
  }

  @override
  String get timeRanOut => 'Time ran out';

  @override
  String get yourAttempts => 'Your attempts';

  @override
  String get filterAll => 'All';

  @override
  String get historyDidntLoad => 'History didn’t load.';

  @override
  String get checkConnection => 'Check your connection and try again.';

  @override
  String get nothingHere => 'Nothing here yet.';

  @override
  String get nothingHereBody =>
      'Finish a quiz while signed in and it will appear here.';

  @override
  String noCategoryAttempts(String category) {
    return 'No $category attempts yet.';
  }

  @override
  String reviewTitle(String category) {
    return '$category review';
  }

  @override
  String attemptSemantic(String category, int score, int total, String date) {
    return '$category, $score out of $total, $date. Review answers';
  }

  @override
  String get back => 'Back';

  @override
  String get loadingAttempts => 'Loading your attempts';

  @override
  String get dailyBadge => 'Daily';

  @override
  String get timedBadge => 'Timed';

  @override
  String get yourStats => 'Your stats';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get currentStreak => 'Current streak';

  @override
  String get bestStreak => 'Best streak';

  @override
  String get quizzesPlayed => 'Quizzes played';

  @override
  String get overallAccuracy => 'Accuracy';

  @override
  String get bestScore => 'Best score';

  @override
  String get averageScore => 'Average';

  @override
  String get recentScores => 'Recent scores';

  @override
  String recentScoresSemantic(int count, String scores) {
    return 'Last $count scores, oldest first: $scores';
  }

  @override
  String get statsEmpty => 'Finish a quiz while signed in to start your stats.';

  @override
  String statsBasis(int count) {
    return 'Based on your last $count saved attempts.';
  }

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get signOut => 'Sign out';

  @override
  String accountMenu(String name) {
    return 'Account: $name';
  }

  @override
  String get signedInFallback => 'Signed in';

  @override
  String get signInNetworkError =>
      'No connection. Check your network and try again.';

  @override
  String get signInPopupBlocked => 'Your browser blocked the sign-in window.';

  @override
  String get signInFailed => 'Google sign-in didn’t work. Please try again.';

  @override
  String get settings => 'Settings';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get vibration => 'Vibration';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get dailyReminderHint =>
      'A notification once a day when a new challenge is ready.';

  @override
  String get remindersDenied =>
      'Notifications are off for QuizOrbit. Turn them on in your phone’s settings.';

  @override
  String get language => 'Language';

  @override
  String get deviceLanguage => 'Device language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get languageNote => 'Questions are in English.';

  @override
  String get showIntro => 'Show the intro again';

  @override
  String get licenses => 'Open-source licences';

  @override
  String get reminderTitle => 'Today’s QuizOrbit challenge is ready';

  @override
  String get reminderBody => 'Ten questions, one go. Know it? Prove it.';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Get started';

  @override
  String get introOneTitle => 'Know it? Prove it.';

  @override
  String get introOneBody =>
      'Pick Anime or Sports, choose a topic, and answer ten questions drawn from over a hundred.';

  @override
  String get introTwoTitle => 'Come back daily.';

  @override
  String get introTwoBody =>
      'A new challenge every day. Sign in to save results, build a streak and review every answer.';

  @override
  String introPage(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get previousQuestion => 'Previous question';

  @override
  String get submitQuiz => 'Submit quiz';

  @override
  String get submitTitle => 'Submit your answers?';

  @override
  String get submitBody =>
      'You can’t change them after this. Your score and the right answers come next.';

  @override
  String get reviewAnswers => 'Review answers';

  @override
  String get alreadyPlayed => 'Already played today';

  @override
  String get alreadyPlayedBody =>
      'Today’s challenge was already saved, probably from another device. The first result is the one that counts.';
}
