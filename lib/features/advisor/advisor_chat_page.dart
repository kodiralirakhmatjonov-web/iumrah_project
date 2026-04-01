// ⚠️ только визуал изменён, логика не тронута

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/features/advisor/ai_chat_page.dart';
import 'package:iumrah_project/home/widgets/advisor_top_nav.dart';

import 'local_ihram_advisor.dart';

class AdvisorChatPage extends StatefulWidget {
  const AdvisorChatPage({super.key});

  @override
  State<AdvisorChatPage> createState() => _AdvisorChatPageState();
}

class _AdvisorChatPageState extends State<AdvisorChatPage> {
  String t(String key) {
    final value = TranslationsStore.get(key).trim();
    if (value.isEmpty || value == key || value == '[$key]') return '';
    return value;
  }

  static const String _cacheKey = 'advisor_chat_page_cache_v1';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  final advisor = LocalIhramAdvisor.instance;

  bool _isTyping = false;
  bool _isReady = false;

  final List<String> _quick = [
    "Что такое умра?",
    "Как надевать ихрам?",
    "Можно ли душ в ихраме?",
    "Можно ли душ в ихраме?",
  ];

  @override
  void initState() {
    super.initState();
    _restoreCachedMessages();
    _initAdvisor();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAdvisor() async {
    await advisor.load();
    if (!mounted) return;
    setState(() => _isReady = true);
  }

  Future<void> _restoreCachedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);

    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final restored = decoded
          .whereType<Map>()
          .map(
            (e) => _ChatMessage.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
      });

      _scrollToBottom(immediate: true);
    } catch (_) {
      // ignore broken cache
    }
  }

  Future<void> _persistMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _messages
        .map(
          (m) => m.copyWith(isStreaming: false).toMap(),
        )
        .toList();

    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: clean, isUser: true));
      _isTyping = true;
    });

    _controller.clear();
    await _persistMessages();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 400));

    final result = advisor.ask(clean);

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(
        _ChatMessage(
          text: '',
          isUser: false,
          suggestions: result.suggestions,
          isStreaming: true,
        ),
      );
    });

    _scrollToBottom();

    await _animateAssistantReply(
      messageIndex: _messages.length - 1,
      fullText: result.answer,
      suggestions: result.suggestions,
    );
  }

  Future<void> _animateAssistantReply({
    required int messageIndex,
    required String fullText,
    required List<String> suggestions,
  }) async {
    final units = fullText.runes.toList();
    var visible = 0;

    final int step = units.length > 320
        ? 4
        : units.length > 180
            ? 3
            : units.length > 90
                ? 2
                : 1;

    final int delayMs = units.length > 320
        ? 8
        : units.length > 180
            ? 10
            : 14;

    while (mounted && visible < units.length) {
      visible = math.min(visible + step, units.length);

      setState(() {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          text: String.fromCharCodes(units.take(visible)),
          suggestions: suggestions,
          isStreaming: visible < units.length,
        );
      });

      _scrollToBottom(immediate: true);
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    if (!mounted) return;

    setState(() {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        text: fullText,
        suggestions: suggestions,
        isStreaming: false,
      );
    });

    await _persistMessages();
    _scrollToBottom();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      if (immediate) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleModeChange(AdvisorMode mode) {
    if (mode == AdvisorMode.chat) return;

    if (mode == AdvisorMode.reading) {
      Navigator.pushReplacement(
        context,
        PremiumRoute.push(const AiChatPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _messages.length + (_isTyping ? 1 : 0);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 🔥 ГРАДИЕНТ СНИЗУ
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, 0.9),
                  radius: 0.7,
                  colors: [
                    Color(0xffF06D13),
                    Color(0x00F06D13),
                  ],
                ),
              ),
            ),
          ),

          /// SafeArea только сверху
          SafeArea(
            top: true,
            bottom: false,
            left: false,
            right: false,
            child: Column(
              children: [
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/advisor_ai_logo.png',
                        height: 65,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const SizedBox(height: 18),

                /// INFO BLOCK
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'advchat_title',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'advchat_warning',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// QUICK CHIPS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final text = _quick[i];
                        return GestureDetector(
                          onTap: () => _sendMessage(text),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF08A1A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: _quick.length,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// MESSAGES
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: totalItems,
                    itemBuilder: (_, i) {
                      if (_isTyping && i == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: _ThinkingDots(),
                        );
                      }

                      final messageIndex =
                          _messages.length - 1 - (_isTyping ? i - 1 : i);
                      final m = _messages[messageIndex];

                      if (m.isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF08A1A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              m.text,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: m.isStreaming
                            ? _StreamingAssistantText(text: m.text)
                            : Text(
                                m.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                /// INPUT ВНИЗУ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _controller,
                            onSubmitted: _sendMessage,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Задайте вопрос про умру',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF08A1A),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () => _sendMessage(_controller.text),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Модель обучена только для хаджа и умры',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),

                SizedBox(height: bottomInset > 0 ? bottomInset : 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String> suggestions;
  final bool isStreaming;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestions = const [],
    this.isStreaming = false,
  });

  _ChatMessage copyWith({
    String? text,
    bool? isUser,
    List<String>? suggestions,
    bool? isStreaming,
  }) {
    return _ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      suggestions: suggestions ?? this.suggestions,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'suggestions': suggestions,
    };
  }

  factory _ChatMessage.fromMap(Map<String, dynamic> map) {
    return _ChatMessage(
      text: (map['text'] ?? '').toString(),
      isUser: map['isUser'] == true,
      suggestions:
          (map['suggestions'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      isStreaming: false,
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotValue(int index) {
    final shifted = (_controller.value - index * 0.16) % 1.0;
    return 0.25 + ((math.sin(shifted * math.pi * 2) + 1) / 2) * 0.75;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final value = _dotValue(index);
              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                child: Transform.translate(
                  offset: Offset(0, -(value - 0.25) * 3),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _StreamingAssistantText extends StatelessWidget {
  final String text;

  const _StreamingAssistantText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.35,
    );

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _TypingCursor(),
          ),
        ],
      ),
    );
  }
}

class _TypingCursor extends StatefulWidget {
  const _TypingCursor();

  @override
  State<_TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<_TypingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.15).animate(_controller),
      child: Container(
        width: 2,
        height: 18,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
