import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

class QuestionDataException implements Exception {
  const QuestionDataException(this.message);
  final String message;

  @override
  String toString() => 'QuestionDataException: $message';
}

/// Validated topics and questions, plus the data version saved with
/// completed attempts.
class QuestionBank {
  QuestionBank._(this.version, this.topics, this._byCategory);

  final String version;
  final List<QuizTopic> topics;
  final Map<QuizCategory, List<Question>> _byCategory;

  List<QuizTopic> topicsFor(QuizCategory category) => [
    for (final topic in topics)
      if (topic.category == category) topic,
  ];

  /// Every question in [category], or only those in [topic].
  List<Question> questionsFor(QuizCategory category, {QuizTopic? topic}) {
    final all = _byCategory[category] ?? const [];
    if (topic == null) return all;
    return [
      for (final q in all)
        if (q.topicId == topic.id) q,
    ];
  }

  QuizTopic? topicById(String? id) {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  /// Parses decoded JSON and throws [QuestionDataException] for anything the
  /// quiz cannot safely play.
  factory QuestionBank.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const QuestionDataException('Question data must be an object.');
    }
    final version = json['version'];
    final rawTopics = json['topics'];
    final rawQuestions = json['questions'];
    if (version is! String || version.trim().isEmpty) {
      throw const QuestionDataException('Question data has no version.');
    }
    if (rawTopics is! List<Object?> || rawTopics.isEmpty) {
      throw const QuestionDataException('Question data has no topics.');
    }
    if (rawQuestions is! List<Object?>) {
      throw const QuestionDataException('Question data has no question list.');
    }

    final topics = <String, QuizTopic>{};
    for (final raw in rawTopics) {
      if (raw is! Map<String, Object?>) {
        throw const QuestionDataException('Each topic must be an object.');
      }
      final (id, categoryId, name) = (raw['id'], raw['category'], raw['name']);
      final category = categoryId is String
          ? QuizCategory.byId(categoryId)
          : null;
      if (id is! String ||
          id.trim().isEmpty ||
          name is! String ||
          name.trim().isEmpty ||
          category == null) {
        throw const QuestionDataException('A topic is malformed.');
      }
      if (topics.containsKey(id)) {
        throw QuestionDataException('Duplicate topic ID "$id".');
      }
      topics[id] = QuizTopic(id: id, category: category, name: name.trim());
    }

    final ids = <String>{};
    final byCategory = {
      for (final category in QuizCategory.values) category: <Question>[],
    };
    final perTopic = {for (final id in topics.keys) id: 0};
    for (final (position, raw) in rawQuestions.indexed) {
      final question = _parseQuestion(raw, position, topics);
      if (!ids.add(question.id)) {
        throw QuestionDataException('Duplicate question ID "${question.id}".');
      }
      byCategory[question.category]!.add(question);
      perTopic[question.topicId] = perTopic[question.topicId]! + 1;
    }
    for (final MapEntry(key: id, value: count) in perTopic.entries) {
      if (count < QuizFormat.questionsPerQuiz) {
        throw QuestionDataException(
          'Topic "$id" has $count questions; '
          'needs at least ${QuizFormat.questionsPerQuiz}.',
        );
      }
    }
    for (final category in QuizCategory.values) {
      if (!topics.values.any((topic) => topic.category == category)) {
        throw QuestionDataException('${category.name} has no topics.');
      }
    }
    return QuestionBank._(version, List.unmodifiable(topics.values), {
      for (final MapEntry(:key, :value) in byCategory.entries)
        key: List.unmodifiable(value),
    });
  }

  static Question _parseQuestion(
    Object? raw,
    int position,
    Map<String, QuizTopic> topics,
  ) {
    QuestionDataException invalid(String reason) =>
        QuestionDataException('Question ${position + 1}: $reason');

    if (raw is! Map<String, Object?>) throw invalid('must be an object.');
    String text(String field) {
      final value = raw[field];
      if (value is! String || value.trim().isEmpty) {
        throw invalid('"$field" must be non-empty text.');
      }
      return value.trim();
    }

    final id = text('id');
    final category = QuizCategory.byId(text('category'));
    if (category == null) throw invalid('unknown category.');
    final topic = topics[text('topic')];
    if (topic == null) throw invalid('unknown topic.');
    if (topic.category != category) {
      throw invalid('topic belongs to another category.');
    }

    final rawOptions = raw['options'];
    if (rawOptions is! List<Object?> ||
        rawOptions.length != QuizFormat.optionsPerQuestion) {
      throw invalid('needs exactly ${QuizFormat.optionsPerQuestion} options.');
    }
    final options = <String>[];
    for (final option in rawOptions) {
      if (option is! String || option.trim().isEmpty) {
        throw invalid('options must be non-empty text.');
      }
      options.add(option.trim());
    }
    if (options.map((o) => o.toLowerCase()).toSet().length != options.length) {
      throw invalid('options must be distinct.');
    }

    final correctIndex = raw['correctIndex'];
    if (correctIndex is! int ||
        correctIndex < 0 ||
        correctIndex >= options.length) {
      throw invalid('"correctIndex" is out of range.');
    }

    return Question(
      id: id,
      category: category,
      topicId: topic.id,
      prompt: text('prompt'),
      options: options,
      correctIndex: correctIndex,
      explanation: text('explanation'),
    );
  }
}

/// Orders bank versions like "2026-11-01.2" so the newest content wins.
int compareBankVersions(String a, String b) {
  final pa = a.split(RegExp(r'[.\-]')).map(int.tryParse).toList();
  final pb = b.split(RegExp(r'[.\-]')).map(int.tryParse).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final (x, y) = (pa[i], pb[i]);
    if (x == null || y == null) return a.compareTo(b);
    if (x != y) return x.compareTo(y);
  }
  return pa.length.compareTo(pb.length);
}

/// Where questions come from. Screens depend on this contract, so tests can
/// supply an in-memory implementation.
abstract interface class QuestionRepository {
  Future<QuestionBank> load();
}

/// Loads the bundled question file. Keeps asset access and parsing out of
/// widgets.
class AssetQuestionRepository implements QuestionRepository {
  const AssetQuestionRepository({
    this.assetPath = 'assets/questions/questions.json',
  });

  final String assetPath;

  @override
  Future<QuestionBank> load() async {
    final String source;
    try {
      source = await rootBundle.loadString(assetPath);
    } on FlutterError {
      throw const QuestionDataException('The question file is missing.');
    }
    try {
      return QuestionBank.fromJson(jsonDecode(source));
    } on FormatException {
      throw const QuestionDataException('The question file is not valid JSON.');
    }
  }
}

/// A source that may be unavailable, such as the published bank in
/// Firestore. Returns null when there is nothing usable.
abstract interface class RemoteQuestionSource {
  Future<QuestionBank?> fetch();
}

/// Uses the published bank when it is valid and at least as new as the
/// bundled one; otherwise the bundled bank. A failed or slow download never
/// blocks play. The chosen bank is kept for the session so every screen
/// (quiz, daily challenge, review) agrees on one version.
class LayeredQuestionRepository implements QuestionRepository {
  LayeredQuestionRepository({required this.bundled, this.remote});

  final QuestionRepository bundled;
  final RemoteQuestionSource? remote;
  Future<QuestionBank>? _loaded;

  @override
  Future<QuestionBank> load() =>
      _loaded ??= _choose().catchError((Object error) {
        _loaded = null; // Let a retry try again.
        throw error;
      });

  Future<QuestionBank> _choose() async {
    final local = await bundled.load();
    QuestionBank? published;
    try {
      published = await remote?.fetch();
    } catch (_) {
      published = null;
    }
    if (published != null &&
        compareBankVersions(published.version, local.version) >= 0) {
      return published;
    }
    return local;
  }
}
