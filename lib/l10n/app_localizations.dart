import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QuizOrbit'**
  String get appTitle;

  /// No description provided for @categoryAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get categoryAnime;

  /// No description provided for @categorySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get categorySports;

  /// No description provided for @heroLineOne.
  ///
  /// In en, this message translates to:
  /// **'KNOW IT?'**
  String get heroLineOne;

  /// No description provided for @heroLineTwo.
  ///
  /// In en, this message translates to:
  /// **'PROVE IT.'**
  String get heroLineTwo;

  /// No description provided for @heroSemantic.
  ///
  /// In en, this message translates to:
  /// **'Know it? Prove it.'**
  String get heroSemantic;

  /// No description provided for @heroBody.
  ///
  /// In en, this message translates to:
  /// **'Anime worlds. Sporting moments.\nA quiz for the fans who know.'**
  String get heroBody;

  /// No description provided for @chooseCategoryAction.
  ///
  /// In en, this message translates to:
  /// **'Choose your category'**
  String get chooseCategoryAction;

  /// No description provided for @chooseCategoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Choose your category.'**
  String get chooseCategoryHeading;

  /// No description provided for @categorySectionNote.
  ///
  /// In en, this message translates to:
  /// **'Over 100 questions in each.'**
  String get categorySectionNote;

  /// No description provided for @animeDescription.
  ///
  /// In en, this message translates to:
  /// **'Characters, worlds, and stories you never forget.'**
  String get animeDescription;

  /// No description provided for @sportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Rules, rivalries, and moments that made the game.'**
  String get sportsDescription;

  /// No description provided for @animeDetail.
  ///
  /// In en, this message translates to:
  /// **'Characters, worlds, and the stories that stay with you.'**
  String get animeDetail;

  /// No description provided for @sportsDetail.
  ///
  /// In en, this message translates to:
  /// **'Rules, rivalries, and the moments that define the game.'**
  String get sportsDetail;

  /// No description provided for @exploreCategory.
  ///
  /// In en, this message translates to:
  /// **'Explore {category}'**
  String exploreCategory(String category);

  /// No description provided for @categoryGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'{category} category'**
  String categoryGroupLabel(String category);

  /// No description provided for @footerTagline.
  ///
  /// In en, this message translates to:
  /// **'A quiz for curious fans.'**
  String get footerTagline;

  /// No description provided for @ringPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get ringPause;

  /// No description provided for @ringPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get ringPlay;

  /// No description provided for @ringPauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause ring animation'**
  String get ringPauseTooltip;

  /// No description provided for @ringResumeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Resume ring animation'**
  String get ringResumeTooltip;

  /// No description provided for @dailyHeading.
  ///
  /// In en, this message translates to:
  /// **'Today’s challenge'**
  String get dailyHeading;

  /// No description provided for @dailyBody.
  ///
  /// In en, this message translates to:
  /// **'The same 10 questions for every player today. One go each.'**
  String get dailyBody;

  /// No description provided for @dailyPlay.
  ///
  /// In en, this message translates to:
  /// **'Play today’s {category}'**
  String dailyPlay(String category);

  /// No description provided for @dailyDone.
  ///
  /// In en, this message translates to:
  /// **'Done today: {score}/{total}'**
  String dailyDone(int score, int total);

  /// No description provided for @dailySignInNote.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your daily result and keep your streak.'**
  String get dailySignInNote;

  /// No description provided for @closeCategory.
  ///
  /// In en, this message translates to:
  /// **'Close category details'**
  String get closeCategory;

  /// No description provided for @inFocus.
  ///
  /// In en, this message translates to:
  /// **'{category}, in focus.'**
  String inFocus(String category);

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String questionsCount(int count);

  /// No description provided for @choicesPerQuestion.
  ///
  /// In en, this message translates to:
  /// **'{count} choices per question'**
  String choicesPerQuestion(int count);

  /// No description provided for @onePointRule.
  ///
  /// In en, this message translates to:
  /// **'One point for every correct answer.'**
  String get onePointRule;

  /// No description provided for @topicLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topicLabel;

  /// No description provided for @allTopics.
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get allTopics;

  /// No description provided for @timedMode.
  ///
  /// In en, this message translates to:
  /// **'Timed mode'**
  String get timedMode;

  /// No description provided for @timedModeHint.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds per question'**
  String timedModeHint(int seconds);

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start {category} quiz'**
  String startQuiz(String category);

  /// No description provided for @backToCategories.
  ///
  /// In en, this message translates to:
  /// **'Back to categories'**
  String get backToCategories;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} quiz'**
  String quizTitle(String category);

  /// No description provided for @dailyQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily {category}'**
  String dailyQuizTitle(String category);

  /// No description provided for @leaveQuiz.
  ///
  /// In en, this message translates to:
  /// **'Leave quiz'**
  String get leaveQuiz;

  /// No description provided for @questionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionProgress(int current, int total);

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Quiz progress'**
  String get progressLabel;

  /// No description provided for @progressValue.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} questions completed'**
  String progressValue(int completed, int total);

  /// No description provided for @questionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Question {number} of {total}. {prompt}'**
  String questionSemantic(int number, int total, String prompt);

  /// No description provided for @chooseAnswer.
  ///
  /// In en, this message translates to:
  /// **'Choose an answer'**
  String get chooseAnswer;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get nextQuestion;

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String secondsLeft(int seconds);

  /// No description provided for @secondsLeftSemantic.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds left'**
  String secondsLeftSemantic(int seconds);

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this quiz?'**
  String get leaveTitle;

  /// No description provided for @leaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers so far will be discarded. Only finished quizzes count.'**
  String get leaveBody;

  /// No description provided for @keepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get keepPlaying;

  /// No description provided for @discardAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Discard and leave'**
  String get discardAndLeave;

  /// No description provided for @loadingQuestions.
  ///
  /// In en, this message translates to:
  /// **'Loading questions…'**
  String get loadingQuestions;

  /// No description provided for @noQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions'**
  String get noQuestions;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWrong;

  /// No description provided for @quizEmpty.
  ///
  /// In en, this message translates to:
  /// **'This quiz is empty.'**
  String get quizEmpty;

  /// No description provided for @questionsDidntLoad.
  ///
  /// In en, this message translates to:
  /// **'Questions didn’t load.'**
  String get questionsDidntLoad;

  /// No description provided for @quizEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'There are no questions for this category yet. Try another category.'**
  String get quizEmptyBody;

  /// No description provided for @questionsErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The question set couldn’t be read. Try again, or choose another category.'**
  String get questionsErrorBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @reportQuestion.
  ///
  /// In en, this message translates to:
  /// **'Report this question'**
  String get reportQuestion;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportTitle;

  /// No description provided for @reportWrong.
  ///
  /// In en, this message translates to:
  /// **'The answer is wrong'**
  String get reportWrong;

  /// No description provided for @reportUnclear.
  ///
  /// In en, this message translates to:
  /// **'The question is unclear'**
  String get reportUnclear;

  /// No description provided for @reportTypo.
  ///
  /// In en, this message translates to:
  /// **'Spelling or typo'**
  String get reportTypo;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportOther;

  /// No description provided for @reportNote.
  ///
  /// In en, this message translates to:
  /// **'Anything to add? (optional)'**
  String get reportNote;

  /// No description provided for @reportSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSend;

  /// No description provided for @reportSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get reportSending;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We’ll check this question.'**
  String get reportSent;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send the report. Try again.'**
  String get reportFailed;

  /// No description provided for @reportSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to report a question.'**
  String get reportSignIn;

  /// No description provided for @reportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reporting isn’t connected in this build.'**
  String get reportUnavailable;

  /// No description provided for @finalScore.
  ///
  /// In en, this message translates to:
  /// **'{category} final score'**
  String finalScore(String category);

  /// No description provided for @verdictPerfect.
  ///
  /// In en, this message translates to:
  /// **'Proved it.'**
  String get verdictPerfect;

  /// No description provided for @verdictGreat.
  ///
  /// In en, this message translates to:
  /// **'You know it.'**
  String get verdictGreat;

  /// No description provided for @verdictOkay.
  ///
  /// In en, this message translates to:
  /// **'Getting there.'**
  String get verdictOkay;

  /// No description provided for @verdictLow.
  ///
  /// In en, this message translates to:
  /// **'Room to grow.'**
  String get verdictLow;

  /// No description provided for @correctChip.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctChip;

  /// No description provided for @missedChip.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missedChip;

  /// No description provided for @scoreSemantic.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} out of {total}'**
  String scoreSemantic(int score, int total);

  /// No description provided for @notSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get notSaved;

  /// No description provided for @unavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Account saving isn’t connected in this build yet. Your score is shown here only.'**
  String get unavailableBody;

  /// No description provided for @signedOutBody.
  ///
  /// In en, this message translates to:
  /// **'You weren’t signed in when you finished. Sign in with Google to save this result to your account.'**
  String get signedOutBody;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @savingBody.
  ///
  /// In en, this message translates to:
  /// **'Saving this result to your account.'**
  String get savingBody;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @savedBody.
  ///
  /// In en, this message translates to:
  /// **'This result is saved to your account. You can review it any time.'**
  String get savedBody;

  /// No description provided for @couldntSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save'**
  String get couldntSave;

  /// No description provided for @failedBody.
  ///
  /// In en, this message translates to:
  /// **'Your score is safe on this screen. Check your connection and try again.'**
  String get failedBody;

  /// No description provided for @retrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry save'**
  String get retrySave;

  /// No description provided for @signInToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save'**
  String get signInToSave;

  /// No description provided for @seeAllAttempts.
  ///
  /// In en, this message translates to:
  /// **'See all your attempts'**
  String get seeAllAttempts;

  /// No description provided for @chooseAnotherCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose another category'**
  String get chooseAnotherCategory;

  /// No description provided for @yourAnswers.
  ///
  /// In en, this message translates to:
  /// **'Your answers'**
  String get yourAnswers;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share result'**
  String get shareResult;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'I scored {score}/{total} in {category} on QuizOrbit. Know it? Prove it.'**
  String shareText(int score, int total, String category);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t share the result.'**
  String get shareFailed;

  /// No description provided for @dailyComeBack.
  ///
  /// In en, this message translates to:
  /// **'That was today’s challenge. A new one is ready tomorrow.'**
  String get dailyComeBack;

  /// No description provided for @playPractice.
  ///
  /// In en, this message translates to:
  /// **'Play a practice quiz'**
  String get playPractice;

  /// No description provided for @questionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String questionNumber(int number);

  /// No description provided for @noLongerInQuiz.
  ///
  /// In en, this message translates to:
  /// **'This question is no longer in the quiz.'**
  String get noLongerInQuiz;

  /// No description provided for @correctOption.
  ///
  /// In en, this message translates to:
  /// **'Correct: {option}'**
  String correctOption(String option);

  /// No description provided for @youChose.
  ///
  /// In en, this message translates to:
  /// **'You chose {option}'**
  String youChose(String option);

  /// No description provided for @answerOption.
  ///
  /// In en, this message translates to:
  /// **'Answer: {option}'**
  String answerOption(String option);

  /// No description provided for @timeRanOut.
  ///
  /// In en, this message translates to:
  /// **'Time ran out'**
  String get timeRanOut;

  /// No description provided for @yourAttempts.
  ///
  /// In en, this message translates to:
  /// **'Your attempts'**
  String get yourAttempts;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @historyDidntLoad.
  ///
  /// In en, this message translates to:
  /// **'History didn’t load.'**
  String get historyDidntLoad;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnection;

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get nothingHere;

  /// No description provided for @nothingHereBody.
  ///
  /// In en, this message translates to:
  /// **'Finish a quiz while signed in and it will appear here.'**
  String get nothingHereBody;

  /// No description provided for @noCategoryAttempts.
  ///
  /// In en, this message translates to:
  /// **'No {category} attempts yet.'**
  String noCategoryAttempts(String category);

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} review'**
  String reviewTitle(String category);

  /// No description provided for @attemptSemantic.
  ///
  /// In en, this message translates to:
  /// **'{category}, {score} out of {total}, {date}. Review answers'**
  String attemptSemantic(String category, int score, int total, String date);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @loadingAttempts.
  ///
  /// In en, this message translates to:
  /// **'Loading your attempts'**
  String get loadingAttempts;

  /// No description provided for @dailyBadge.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyBadge;

  /// No description provided for @timedBadge.
  ///
  /// In en, this message translates to:
  /// **'Timed'**
  String get timedBadge;

  /// No description provided for @yourStats.
  ///
  /// In en, this message translates to:
  /// **'Your stats'**
  String get yourStats;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String streakDays(int count);

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get bestStreak;

  /// No description provided for @quizzesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Quizzes played'**
  String get quizzesPlayed;

  /// No description provided for @overallAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get overallAccuracy;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best score'**
  String get bestScore;

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get averageScore;

  /// No description provided for @recentScores.
  ///
  /// In en, this message translates to:
  /// **'Recent scores'**
  String get recentScores;

  /// No description provided for @recentScoresSemantic.
  ///
  /// In en, this message translates to:
  /// **'Last {count} scores, oldest first: {scores}'**
  String recentScoresSemantic(int count, String scores);

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Finish a quiz while signed in to start your stats.'**
  String get statsEmpty;

  /// No description provided for @statsBasis.
  ///
  /// In en, this message translates to:
  /// **'Based on your last {count} saved attempts.'**
  String statsBasis(int count);

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @accountMenu.
  ///
  /// In en, this message translates to:
  /// **'Account: {name}'**
  String accountMenu(String name);

  /// No description provided for @signedInFallback.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedInFallback;

  /// No description provided for @signInNetworkError.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get signInNetworkError;

  /// No description provided for @signInPopupBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your browser blocked the sign-in window.'**
  String get signInPopupBlocked;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in didn’t work. Please try again.'**
  String get signInFailed;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @dailyReminderHint.
  ///
  /// In en, this message translates to:
  /// **'A notification once a day when a new challenge is ready.'**
  String get dailyReminderHint;

  /// No description provided for @remindersDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for QuizOrbit. Turn them on in your phone’s settings.'**
  String get remindersDenied;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @deviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get deviceLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// No description provided for @languageNote.
  ///
  /// In en, this message translates to:
  /// **'Questions are in English.'**
  String get languageNote;

  /// No description provided for @showIntro.
  ///
  /// In en, this message translates to:
  /// **'Show the intro again'**
  String get showIntro;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licenses;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Today’s QuizOrbit challenge is ready'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Ten questions, one go. Know it? Prove it.'**
  String get reminderBody;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get introStart;

  /// No description provided for @introOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Know it? Prove it.'**
  String get introOneTitle;

  /// No description provided for @introOneBody.
  ///
  /// In en, this message translates to:
  /// **'Pick Anime or Sports, choose a topic, and answer ten questions drawn from over a hundred.'**
  String get introOneBody;

  /// No description provided for @introTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Come back daily.'**
  String get introTwoTitle;

  /// No description provided for @introTwoBody.
  ///
  /// In en, this message translates to:
  /// **'A new challenge every day. Sign in to save results, build a streak and review every answer.'**
  String get introTwoBody;

  /// No description provided for @introPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String introPage(int page, int total);

  /// No description provided for @previousQuestion.
  ///
  /// In en, this message translates to:
  /// **'Previous question'**
  String get previousQuestion;

  /// No description provided for @submitQuiz.
  ///
  /// In en, this message translates to:
  /// **'Submit quiz'**
  String get submitQuiz;

  /// No description provided for @submitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your answers?'**
  String get submitTitle;

  /// No description provided for @submitBody.
  ///
  /// In en, this message translates to:
  /// **'You can’t change them after this. Your score and the right answers come next.'**
  String get submitBody;

  /// No description provided for @reviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Review answers'**
  String get reviewAnswers;

  /// No description provided for @alreadyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Already played today'**
  String get alreadyPlayed;

  /// No description provided for @alreadyPlayedBody.
  ///
  /// In en, this message translates to:
  /// **'Today’s challenge was already saved, probably from another device. The first result is the one that counts.'**
  String get alreadyPlayedBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
