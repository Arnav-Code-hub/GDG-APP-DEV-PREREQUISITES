// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'QuizOrbit';

  @override
  String get categoryAnime => 'एनीमे';

  @override
  String get categorySports => 'खेल';

  @override
  String get heroLineOne => 'जानते हो?';

  @override
  String get heroLineTwo => 'साबित करो।';

  @override
  String get heroSemantic => 'जानते हो? साबित करो।';

  @override
  String get heroBody =>
      'एनीमे की दुनिया। खेल के यादगार पल।\nसच्चे फ़ैन्स के लिए एक क्विज़।';

  @override
  String get chooseCategoryAction => 'अपनी श्रेणी चुनें';

  @override
  String get chooseCategoryHeading => 'अपनी श्रेणी चुनें।';

  @override
  String get categorySectionNote => 'हर श्रेणी में 100 से ज़्यादा सवाल।';

  @override
  String get animeDescription =>
      'किरदार, दुनियाएँ और कहानियाँ जो आप कभी नहीं भूलते।';

  @override
  String get sportsDescription =>
      'नियम, मुक़ाबले और वे पल जिन्होंने खेल को बनाया।';

  @override
  String get animeDetail =>
      'किरदार, दुनियाएँ और वे कहानियाँ जो दिल में रह जाती हैं।';

  @override
  String get sportsDetail => 'नियम, मुक़ाबले और वे पल जो खेल की पहचान हैं।';

  @override
  String exploreCategory(String category) {
    return '$category देखें';
  }

  @override
  String categoryGroupLabel(String category) {
    return '$category श्रेणी';
  }

  @override
  String get footerTagline => 'जिज्ञासु फ़ैन्स के लिए एक क्विज़।';

  @override
  String get ringPause => 'रोकें';

  @override
  String get ringPlay => 'चलाएँ';

  @override
  String get ringPauseTooltip => 'रिंग एनिमेशन रोकें';

  @override
  String get ringResumeTooltip => 'रिंग एनिमेशन फिर चलाएँ';

  @override
  String get dailyHeading => 'आज की चुनौती';

  @override
  String get dailyBody =>
      'आज हर खिलाड़ी के लिए वही 10 सवाल। हर किसी को एक मौका।';

  @override
  String dailyPlay(String category) {
    return 'आज का $category खेलें';
  }

  @override
  String dailyDone(int score, int total) {
    return 'आज पूरा: $score/$total';
  }

  @override
  String get dailySignInNote =>
      'अपना दैनिक नतीजा सहेजने और लगातार खेलने का रिकॉर्ड बनाने के लिए साइन इन करें।';

  @override
  String get closeCategory => 'श्रेणी विवरण बंद करें';

  @override
  String inFocus(String category) {
    return '$category, नज़दीक से।';
  }

  @override
  String get howItWorks => 'कैसे खेलें';

  @override
  String questionsCount(int count) {
    return '$count सवाल';
  }

  @override
  String choicesPerQuestion(int count) {
    return 'हर सवाल में $count विकल्प';
  }

  @override
  String get onePointRule => 'हर सही जवाब पर एक अंक।';

  @override
  String get topicLabel => 'विषय';

  @override
  String get allTopics => 'सभी विषय';

  @override
  String get timedMode => 'समय-सीमा मोड';

  @override
  String timedModeHint(int seconds) {
    return 'हर सवाल के लिए $seconds सेकंड';
  }

  @override
  String startQuiz(String category) {
    return '$category क्विज़ शुरू करें';
  }

  @override
  String get backToCategories => 'श्रेणियों पर वापस';

  @override
  String quizTitle(String category) {
    return '$category क्विज़';
  }

  @override
  String dailyQuizTitle(String category) {
    return 'दैनिक $category';
  }

  @override
  String get leaveQuiz => 'क्विज़ छोड़ें';

  @override
  String questionProgress(int current, int total) {
    return 'सवाल $current / $total';
  }

  @override
  String get progressLabel => 'क्विज़ की प्रगति';

  @override
  String progressValue(int completed, int total) {
    return '$total में से $completed सवाल पूरे';
  }

  @override
  String questionSemantic(int number, int total, String prompt) {
    return 'सवाल $number / $total। $prompt';
  }

  @override
  String get chooseAnswer => 'जवाब चुनें';

  @override
  String get nextQuestion => 'अगला सवाल';

  @override
  String secondsLeft(int seconds) {
    return '$seconds से.';
  }

  @override
  String secondsLeftSemantic(int seconds) {
    return '$seconds सेकंड बाकी';
  }

  @override
  String get leaveTitle => 'क्विज़ छोड़ना है?';

  @override
  String get leaveBody =>
      'अब तक के जवाब हटा दिए जाएँगे। सिर्फ़ पूरे किए गए क्विज़ गिने जाते हैं।';

  @override
  String get keepPlaying => 'खेलते रहें';

  @override
  String get discardAndLeave => 'हटाएँ और छोड़ें';

  @override
  String get loadingQuestions => 'सवाल लोड हो रहे हैं…';

  @override
  String get noQuestions => 'कोई सवाल नहीं';

  @override
  String get somethingWrong => 'कुछ गड़बड़ हुई';

  @override
  String get quizEmpty => 'यह क्विज़ खाली है।';

  @override
  String get questionsDidntLoad => 'सवाल लोड नहीं हुए।';

  @override
  String get quizEmptyBody =>
      'इस श्रेणी में अभी कोई सवाल नहीं है। कोई और श्रेणी आज़माएँ।';

  @override
  String get questionsErrorBody =>
      'सवालों का सेट पढ़ा नहीं जा सका। फिर से कोशिश करें या कोई और श्रेणी चुनें।';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get reportQuestion => 'इस सवाल की शिकायत करें';

  @override
  String get reportTitle => 'समस्या बताएँ';

  @override
  String get reportWrong => 'जवाब ग़लत है';

  @override
  String get reportUnclear => 'सवाल साफ़ नहीं है';

  @override
  String get reportTypo => 'वर्तनी या टाइपिंग की ग़लती';

  @override
  String get reportOther => 'कुछ और';

  @override
  String get reportNote => 'कुछ और जोड़ना है? (वैकल्पिक)';

  @override
  String get reportSend => 'शिकायत भेजें';

  @override
  String get reportSending => 'भेजा जा रहा है…';

  @override
  String get reportSent => 'धन्यवाद। हम इस सवाल को जाँचेंगे।';

  @override
  String get reportFailed => 'शिकायत नहीं भेजी जा सकी। फिर से कोशिश करें।';

  @override
  String get reportSignIn => 'सवाल की शिकायत करने के लिए साइन इन करें।';

  @override
  String get reportUnavailable => 'इस बिल्ड में शिकायत भेजना जुड़ा नहीं है।';

  @override
  String finalScore(String category) {
    return '$category का अंतिम स्कोर';
  }

  @override
  String get verdictPerfect => 'साबित कर दिया।';

  @override
  String get verdictGreat => 'आप जानते हैं।';

  @override
  String get verdictOkay => 'बढ़िया कोशिश।';

  @override
  String get verdictLow => 'अभी और सीखना है।';

  @override
  String get correctChip => 'सही';

  @override
  String get missedChip => 'छूटे';

  @override
  String scoreSemantic(int score, int total) {
    return 'स्कोर: $total में से $score';
  }

  @override
  String get notSaved => 'सहेजा नहीं गया';

  @override
  String get unavailableBody =>
      'इस बिल्ड में खाते में सहेजना अभी जुड़ा नहीं है। आपका स्कोर सिर्फ़ यहीं दिख रहा है।';

  @override
  String get signedOutBody =>
      'क्विज़ पूरा करते समय आप साइन इन नहीं थे। यह नतीजा अपने खाते में सहेजने के लिए Google से साइन इन करें।';

  @override
  String get saving => 'सहेजा जा रहा है…';

  @override
  String get savingBody => 'यह नतीजा आपके खाते में सहेजा जा रहा है।';

  @override
  String get saved => 'सहेजा गया';

  @override
  String get savedBody =>
      'यह नतीजा आपके खाते में सहेजा गया है। आप इसे कभी भी दोबारा देख सकते हैं।';

  @override
  String get couldntSave => 'सहेजा नहीं जा सका';

  @override
  String get failedBody =>
      'आपका स्कोर इस स्क्रीन पर सुरक्षित है। कनेक्शन जाँचें और फिर से कोशिश करें।';

  @override
  String get retrySave => 'फिर से सहेजें';

  @override
  String get signInToSave => 'सहेजने के लिए साइन इन करें';

  @override
  String get seeAllAttempts => 'अपने सभी प्रयास देखें';

  @override
  String get chooseAnotherCategory => 'कोई और श्रेणी चुनें';

  @override
  String get yourAnswers => 'आपके जवाब';

  @override
  String get shareResult => 'नतीजा शेयर करें';

  @override
  String shareText(int score, int total, String category) {
    return 'मैंने QuizOrbit पर $category में $total में से $score स्कोर किया। जानते हो? साबित करो।';
  }

  @override
  String get shareFailed => 'नतीजा शेयर नहीं हो सका।';

  @override
  String get dailyComeBack => 'यह आज की चुनौती थी। कल नई चुनौती तैयार होगी।';

  @override
  String get playPractice => 'अभ्यास क्विज़ खेलें';

  @override
  String questionNumber(int number) {
    return 'सवाल $number';
  }

  @override
  String get noLongerInQuiz => 'यह सवाल अब क्विज़ में नहीं है।';

  @override
  String correctOption(String option) {
    return 'सही: $option';
  }

  @override
  String youChose(String option) {
    return 'आपने चुना $option';
  }

  @override
  String answerOption(String option) {
    return 'जवाब: $option';
  }

  @override
  String get timeRanOut => 'समय ख़त्म हो गया';

  @override
  String get yourAttempts => 'आपके प्रयास';

  @override
  String get filterAll => 'सभी';

  @override
  String get historyDidntLoad => 'इतिहास लोड नहीं हुआ।';

  @override
  String get checkConnection => 'कनेक्शन जाँचें और फिर से कोशिश करें।';

  @override
  String get nothingHere => 'अभी यहाँ कुछ नहीं है।';

  @override
  String get nothingHereBody =>
      'साइन इन रहते हुए कोई क्विज़ पूरा करें, वह यहाँ दिखेगा।';

  @override
  String noCategoryAttempts(String category) {
    return 'अभी कोई $category प्रयास नहीं।';
  }

  @override
  String reviewTitle(String category) {
    return '$category समीक्षा';
  }

  @override
  String attemptSemantic(String category, int score, int total, String date) {
    return '$category, $total में से $score, $date। जवाब देखें';
  }

  @override
  String get back => 'वापस';

  @override
  String get loadingAttempts => 'आपके प्रयास लोड हो रहे हैं';

  @override
  String get dailyBadge => 'दैनिक';

  @override
  String get timedBadge => 'समय-सीमा';

  @override
  String get yourStats => 'आपके आँकड़े';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get currentStreak => 'लगातार खेलने के दिन';

  @override
  String get bestStreak => 'सबसे लंबा सिलसिला';

  @override
  String get quizzesPlayed => 'खेले गए क्विज़';

  @override
  String get overallAccuracy => 'सटीकता';

  @override
  String get bestScore => 'सबसे अच्छा स्कोर';

  @override
  String get averageScore => 'औसत';

  @override
  String get recentScores => 'हाल के स्कोर';

  @override
  String recentScoresSemantic(int count, String scores) {
    return 'पिछले $count स्कोर, पुराने से नए: $scores';
  }

  @override
  String get statsEmpty =>
      'अपने आँकड़े शुरू करने के लिए साइन इन रहते हुए कोई क्विज़ पूरा करें।';

  @override
  String statsBasis(int count) {
    return 'आपके पिछले $count सहेजे गए प्रयासों के आधार पर।';
  }

  @override
  String get signInWithGoogle => 'Google से साइन इन करें';

  @override
  String get signingIn => 'साइन इन हो रहा है…';

  @override
  String get signOut => 'साइन आउट';

  @override
  String accountMenu(String name) {
    return 'खाता: $name';
  }

  @override
  String get signedInFallback => 'साइन इन है';

  @override
  String get signInNetworkError =>
      'इंटरनेट कनेक्शन नहीं है। नेटवर्क जाँचें और फिर से कोशिश करें।';

  @override
  String get signInPopupBlocked => 'आपके ब्राउज़र ने साइन-इन विंडो रोक दी।';

  @override
  String get signInFailed =>
      'Google साइन-इन नहीं हुआ। कृपया फिर से कोशिश करें।';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get soundEffects => 'साउंड इफ़ेक्ट';

  @override
  String get vibration => 'वाइब्रेशन';

  @override
  String get dailyReminder => 'रोज़ का रिमाइंडर';

  @override
  String get dailyReminderHint =>
      'नई चुनौती तैयार होने पर दिन में एक बार सूचना।';

  @override
  String get remindersDenied =>
      'QuizOrbit की सूचनाएँ बंद हैं। उन्हें फ़ोन की सेटिंग्स में चालू करें।';

  @override
  String get language => 'भाषा';

  @override
  String get deviceLanguage => 'डिवाइस की भाषा';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get languageNote => 'सवाल अंग्रेज़ी में हैं।';

  @override
  String get showIntro => 'परिचय फिर से दिखाएँ';

  @override
  String get licenses => 'ओपन-सोर्स लाइसेंस';

  @override
  String get reminderTitle => 'आज की QuizOrbit चुनौती तैयार है';

  @override
  String get reminderBody => 'दस सवाल, एक मौका। जानते हो? साबित करो।';

  @override
  String get introSkip => 'छोड़ें';

  @override
  String get introNext => 'आगे';

  @override
  String get introStart => 'शुरू करें';

  @override
  String get introOneTitle => 'जानते हो? साबित करो।';

  @override
  String get introOneBody =>
      'एनीमे या खेल चुनें, कोई विषय चुनें, और सौ से ज़्यादा सवालों में से चुने गए दस सवालों के जवाब दें।';

  @override
  String get introTwoTitle => 'रोज़ वापस आएँ।';

  @override
  String get introTwoBody =>
      'हर दिन एक नई चुनौती। नतीजे सहेजने, सिलसिला बनाने और हर जवाब दोबारा देखने के लिए साइन इन करें।';

  @override
  String introPage(int page, int total) {
    return 'पेज $page / $total';
  }

  @override
  String get previousQuestion => 'पिछला सवाल';

  @override
  String get submitQuiz => 'क्विज़ जमा करें';

  @override
  String get submitTitle => 'जवाब जमा करें?';

  @override
  String get submitBody =>
      'इसके बाद जवाब बदले नहीं जा सकेंगे। फिर आपका स्कोर और सही जवाब दिखेंगे।';

  @override
  String get reviewAnswers => 'जवाब दोबारा देखें';

  @override
  String get alreadyPlayed => 'आज पहले ही खेल चुके हैं';

  @override
  String get alreadyPlayedBody =>
      'आज की चुनौती पहले ही सहेजी जा चुकी है, शायद किसी दूसरे डिवाइस से। पहला नतीजा ही गिना जाता है।';
}
