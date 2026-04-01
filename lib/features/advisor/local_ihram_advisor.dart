import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class IntentAnswer {
  final String short;
  final String full;

  const IntentAnswer({
    required this.short,
    required this.full,
  });

  factory IntentAnswer.fromJson(Map<String, dynamic> json) {
    return IntentAnswer(
      short: (json['short'] ?? '').toString(),
      full: (json['full'] ?? '').toString(),
    );
  }
}

class IntentBlock {
  final String id;
  final String intent;
  final List<String> patterns;
  final List<String> keywords;
  final IntentAnswer answer;
  final List<String> related;

  const IntentBlock({
    required this.id,
    required this.intent,
    required this.patterns,
    required this.keywords,
    required this.answer,
    required this.related,
  });

  factory IntentBlock.fromJson(Map<String, dynamic> json) {
    return IntentBlock(
      id: (json['id'] ?? '').toString(),
      intent: (json['intent'] ?? '').toString(),
      patterns: (json['patterns'] is List)
          ? (json['patterns'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
      keywords: (json['keywords'] is List)
          ? (json['keywords'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
      answer: IntentAnswer.fromJson(
        (json['answer'] is Map<String, dynamic>)
            ? json['answer'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      related: (json['related'] is List)
          ? (json['related'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
    );
  }
}

class AdvisorResult {
  final bool found;
  final String answer;
  final String matchedIntentId;
  final double confidence;
  final List<String> suggestions;

  const AdvisorResult({
    required this.found,
    required this.answer,
    required this.matchedIntentId,
    required this.confidence,
    this.suggestions = const [],
  });
}

class _ScoredIntent {
  final IntentBlock intent;
  final int score;

  const _ScoredIntent({
    required this.intent,
    required this.score,
  });
}

class LocalIhramAdvisor {
  LocalIhramAdvisor._();

  static final LocalIhramAdvisor instance = LocalIhramAdvisor._();

  final List<IntentBlock> _intents = [];

  bool _isLoaded = false;
  String? _lastError;

  bool get isLoaded => _isLoaded;
  String? get lastError => _lastError;
  int get intentsCount => _intents.length;

  Future<void> load({
    String assetPath = 'assets/advisor/ru.json',
    bool forceReload = false,
  }) async {
    if (_isLoaded && !forceReload) return;

    _isLoaded = false;
    _lastError = null;
    _intents.clear();

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        _lastError = 'JSON root is not an object';
        return;
      }

      final dynamic intentsRaw = decoded['intents'];

      if (intentsRaw is! List) {
        _lastError = 'JSON does not contain a valid "intents" array';
        return;
      }

      final parsed = intentsRaw
          .whereType<Map<String, dynamic>>()
          .map(IntentBlock.fromJson)
          .where(
            (e) =>
                e.id.isNotEmpty &&
                e.intent.isNotEmpty &&
                e.answer.short.trim().isNotEmpty,
          )
          .toList();

      if (parsed.isEmpty) {
        _lastError = 'No valid intents found in JSON';
        return;
      }

      _intents.addAll(parsed);
      _isLoaded = true;
    } catch (e) {
      _lastError = e.toString();
      _isLoaded = false;
    }
  }

  AdvisorResult ask(String rawMessage) {
    final message = rawMessage.trim();

    if (message.isEmpty) {
      return const AdvisorResult(
        found: false,
        answer: 'Напишите вопрос об ихраме.',
        matchedIntentId: '',
        confidence: 0,
      );
    }

    if (!_isLoaded || _intents.isEmpty) {
      return AdvisorResult(
        found: false,
        answer: _lastError == null
            ? 'База знаний ещё не загружена.'
            : 'Не удалось загрузить базу знаний: $_lastError',
        matchedIntentId: '',
        confidence: 0,
      );
    }

    final normalizedQuery = _normalize(message);
    final queryTokens = _expandTokens(_tokenize(normalizedQuery));

    final scored = _intents.map((intent) {
      final score = _scoreIntent(
        intent: intent,
        normalizedQuery: normalizedQuery,
        queryTokens: queryTokens,
      );
      return _ScoredIntent(intent: intent, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    final best = scored.first;
    final second = scored.length > 1 ? scored[1] : null;

    final confidence = _computeConfidence(best, second);

    if (best.score < 20) {
      return const AdvisorResult(
        found: false,
        answer:
            'Я не уверен, что правильно понял вопрос. Спросите вопросы касающиеся только хаджа и умры например, про душ, волосы, духи, ногти, миқат или выход из ихрама.',
        matchedIntentId: '',
        confidence: 0,
      );
    }

    if (second != null && best.score < 45 && (best.score - second.score) <= 4) {
      return const AdvisorResult(
        found: false,
        answer:
            'Вопрос звучит двусмысленно. Сформулируйте конкретнее: вы спрашиваете о душе, о волосах, о духах, о ногтях или о выходе из ихрама?',
        matchedIntentId: '',
        confidence: 0.4,
      );
    }

    final shortAnswer = best.intent.answer.short.trim();
    final fullAnswer = best.intent.answer.full.trim();

    final answer = fullAnswer.isEmpty || fullAnswer == shortAnswer
        ? shortAnswer
        : '$shortAnswer\n\n$fullAnswer';

    return AdvisorResult(
      found: true,
      answer: answer,
      matchedIntentId: best.intent.id,
      confidence: confidence,
      suggestions: const [], // специально пусто: не показываем похожие вопросы
    );
  }

  int _scoreIntent({
    required IntentBlock intent,
    required String normalizedQuery,
    required Set<String> queryTokens,
  }) {
    int score = 0;

    final intentPatternTexts = intent.patterns.map(_normalize).toList();
    final intentKeywordTexts = intent.keywords.map(_normalize).toList();

    for (final pattern in intentPatternTexts) {
      if (pattern.isEmpty) continue;

      if (normalizedQuery == pattern) {
        score += 140;
      } else if (normalizedQuery.contains(pattern)) {
        score += 85;
      } else if (pattern.contains(normalizedQuery) &&
          normalizedQuery.length >= 4) {
        score += 60;
      }

      final patternTokens = _expandTokens(_tokenize(pattern));
      final overlap = queryTokens.intersection(patternTokens).length;
      score += overlap * 10;
    }

    for (final keyword in intentKeywordTexts) {
      if (keyword.isEmpty) continue;

      if (normalizedQuery.contains(keyword)) {
        score += 24;
      }

      final keywordTokens = _expandTokens(_tokenize(keyword));
      final overlap = queryTokens.intersection(keywordTokens).length;
      score += overlap * 14;
    }

    // Учитываем текст ответа как слабый дополнительный сигнал
    final answerText = _normalize(
      '${intent.answer.short} ${intent.answer.full}',
    );
    final answerTokens = _expandTokens(_tokenize(answerText));
    final answerOverlap = queryTokens.intersection(answerTokens).length;
    score += answerOverlap * 3;

    // Специальные доменные бусты
    if (_containsAny(queryTokens, {'душ', 'мыться', 'купаться', 'вода'}) &&
        intent.id == 'ihram_shower') {
      score += 55;
    }

    if (_containsAny(queryTokens, {'волосы', 'волос', 'стричь', 'брить'}) &&
        intent.id == 'ihram_hair') {
      score += 55;
    }

    if (_containsAny(queryTokens, {'духи', 'парфюм', 'аромат', 'запах'}) &&
        intent.id == 'ihram_perfume') {
      score += 55;
    }

    if (_containsAny(queryTokens, {'ногти', 'ноготь'}) &&
        intent.id == 'ihram_nails') {
      score += 55;
    }

    if (_containsAny(queryTokens, {'лицо', 'никаб'}) &&
        intent.id == 'ihram_face') {
      score += 55;
    }

    if (_containsAny(queryTokens, {'микат', 'миката'}) &&
        intent.id == 'ihram_miqat') {
      score += 55;
    }

    if (_containsAny(queryTokens, {'выйти', 'завершить', 'заканчивается'}) &&
        intent.id == 'ihram_exit') {
      score += 55;
    }

    if (_containsAny(queryTokens, {'женщина', 'женщине', 'женщины'}) &&
        intent.id == 'ihram_clothes_women') {
      score += 30;
    }

    if (_containsAny(queryTokens, {'мужчина', 'мужчине', 'мужчины'}) &&
        intent.id == 'ihram_clothes_men') {
      score += 30;
    }

    return score;
  }

  double _computeConfidence(_ScoredIntent best, _ScoredIntent? second) {
    if (best.score <= 0) return 0;
    if (second == null) return 1;

    final diff = best.score - second.score;
    if (diff >= 50) return 0.98;
    if (diff >= 30) return 0.9;
    if (diff >= 15) return 0.8;
    if (diff >= 8) return 0.68;
    return 0.55;
  }

  bool _containsAny(Set<String> haystack, Set<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<String> _tokenize(String text) {
    const stopWords = {
      'и',
      'в',
      'во',
      'на',
      'с',
      'со',
      'по',
      'к',
      'ко',
      'у',
      'о',
      'об',
      'от',
      'до',
      'за',
      'под',
      'при',
      'не',
      'ли',
      'а',
      'но',
      'или',
      'что',
      'это',
      'как',
      'какой',
      'какая',
      'какие',
      'можно',
      'нужно',
      'если',
      'для',
      'про',
      'мне',
      'я',
      'мы',
      'вы',
      'он',
      'она',
      'они',
      'же',
      'бы',
      'быть',
      'вопрос',
      'вопросы',
    };

    return text
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.length >= 2 && !stopWords.contains(e))
        .toSet();
  }

  Set<String> _expandTokens(Set<String> tokens) {
    final expanded = <String>{...tokens};

    const synonyms = <String, List<String>>{
      'душ': ['мыться', 'купаться', 'вода', 'гигиена'],
      'мыться': ['душ', 'купаться', 'вода'],
      'купаться': ['душ', 'мыться', 'вода'],
      'вода': ['душ', 'мыться', 'купаться'],
      'волос': ['волосы', 'стричь', 'брить', 'удалять'],
      'волосы': ['волос', 'стричь', 'брить', 'удалять'],
      'стричь': ['волосы', 'брить', 'удалять'],
      'брить': ['волосы', 'стричь', 'удалять'],
      'духи': ['парфюм', 'аромат', 'запах'],
      'парфюм': ['духи', 'аромат', 'запах'],
      'аромат': ['духи', 'парфюм', 'запах'],
      'запах': ['духи', 'парфюм', 'аромат'],
      'ноготь': ['ногти'],
      'ногти': ['ноготь'],
      'лицо': ['никаб'],
      'никаб': ['лицо'],
      'микат': ['миката'],
      'миката': ['микат'],
      'выйти': ['завершить', 'заканчивается'],
      'завершить': ['выйти', 'заканчивается'],
      'заканчивается': ['выйти', 'завершить'],
      'женщина': ['женщине', 'женщины'],
      'женщине': ['женщина', 'женщины'],
      'женщины': ['женщина', 'женщине'],
      'мужчина': ['мужчине', 'мужчины'],
      'мужчине': ['мужчина', 'мужчины'],
      'мужчины': ['мужчина', 'мужчине'],
    };

    for (final token in tokens) {
      final related = synonyms[token];
      if (related != null) {
        expanded.addAll(related);
      }
    }

    return expanded;
  }
}
