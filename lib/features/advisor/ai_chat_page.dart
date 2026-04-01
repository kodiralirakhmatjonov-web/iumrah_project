import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/features/advisor/advisor_chat_page.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  static const String _rightIconAsset = 'assets/icons/advisor_right_icon.png';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = <Map<String, String>>[];

  bool _loading = false;
  double _switchValue = 1.0; // 0 = Offline, 1 = Pro

  Future<void> send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _loading = true;
    });

    _controller.clear();
    _scrollToBottom();

    String detectLang(String text) {
      if (RegExp(r'[а-яА-Я]').hasMatch(text)) return 'ru';
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) return 'ar';
      if (RegExp(r'[\u0980-\u09FF]').hasMatch(text)) return 'bn';

      final t = text.toLowerCase();
      if (t.contains('hola')) return 'es';
      if (t.contains('bonjour')) return 'fr';
      if (t.contains('merhaba')) return 'tr';
      if (t.contains('apa') || t.contains('saya')) return 'id';
      if (t.contains('tidak') || t.contains('dan')) return 'ms';

      return 'en';
    }

    String getRefusal(String lang) {
      const map = {
        'ru':
            'Извините, этот AI-гид отвечает только на вопросы, связанные с хаджем и умрой.',
        'en':
            'Sorry, this AI guide only answers questions related to Hajj and Umrah.',
        'ar':
            'عذرًا، هذا الدليل الذكي يجيب فقط على الأسئلة المتعلقة بالحج والعمرة.',
        'tr':
            'Üzgünüz, bu yapay zeka rehberi yalnızca Hac ve Umre ile ilgili soruları yanıtlar.',
        'id':
            'Maaf, panduan AI ini hanya menjawab pertanyaan terkait Haji dan Umrah.',
        'ms':
            'Maaf, panduan AI ini hanya menjawab soalan berkaitan Haji dan Umrah.',
        'bn':
            'দুঃখিত, এই AI গাইড শুধুমাত্র হজ ও উমরাহ সম্পর্কিত প্রশ্নের উত্তর দেয়।',
        'ur':
            'معذرت، یہ AI گائیڈ صرف حج اور عمرہ سے متعلق سوالات کے جواب دیتا ہے۔',
        'fr':
            'Désolé, ce guide IA ne répond qu’aux questions liées au Hajj et à la Omra.',
        'es':
            'Lo siento, este asistente de IA solo responde preguntas relacionadas con el Hajj y la Umrah.',
      };

      return map[lang] ?? map['en']!;
    }

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'iumrah-ai',
        body: {"question": text},
      );
      final dynamic data = res.data;
      final lang = detectLang(text);

      final answer = data is Map && data["text"] != null
          ? data["text"].toString()
          : getRefusal(lang);

      setState(() {
        _messages.add({"role": "ai", "text": answer});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": "Ошибка соединения"});
      });
    }

    setState(() => _loading = false);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _goBack() {
    Navigator.of(context).maybePop();
  }

  void _goOffline() {
    setState(() {
      _switchValue = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PremiumRoute.push(const AdvisorChatPage()),
      );
    });
  }

  void _stayOnPro() {
    setState(() {
      _switchValue = 1.0;
    });
  }

  Widget _assetIcon({
    required String path,
    required double size,
    required IconData fallback,
    Color fallbackColor = const Color(0xFF2A2A2A),
  }) {
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Icon(
          fallback,
          size: size,
          color: fallbackColor,
        );
      },
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Advisor AI',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
              ],
            ),
          ),
          _PremiumTap(
            onTap: _goBack,
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22FFFFFF),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: AlignmentDirectional.center,
              child: _assetIcon(
                path: _rightIconAsset,
                size: 21,
                fallback: Icons.arrow_back_ios_new_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final knobWidth = (width - 8) / 2;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (details.localPosition.dx < width / 2) {
              _goOffline();
            } else {
              _stayOnPro();
            }
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _switchValue += details.delta.dx / (width / 2);
              _switchValue = _switchValue.clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_switchValue < 0.5) {
              _goOffline();
            } else {
              _stayOnPro();
            }
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                PositionedDirectional(
                  top: 4,
                  bottom: 4,
                  start: 4 + ((width - knobWidth - 8) * _switchValue),
                  child: Container(
                    width: knobWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                        colors: [
                          Color(0xFF402B15),
                          Color(0xFFFF9C00),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55FF9800),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          'Advisor Offline',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: _switchValue < 0.5
                                ? Colors.white
                                : const Color(0xFF8C8C8C),
                            fontSize: 16,
                            fontWeight: _switchValue < 0.5
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          'Advisor Pro',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: _switchValue >= 0.5
                                ? Colors.white
                                : const Color(0xFF8C8C8C),
                            fontSize: 16,
                            fontWeight: _switchValue >= 0.5
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroText() {
    return const Column(
      children: [
        Text(
          'Premium Umrah Assistant',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFF9800),
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.06,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Advisor AI обучен на базе данных\nминистерства хаджа и умры и отвечает\nтолько из достоверных источников, без\nвозможности случайных ответов',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.8,
            fontWeight: FontWeight.w700,
            height: 1.18,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              width: 356,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(27),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55FF9800),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 214,
              height: 214,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble({
    required String text,
    required bool isUser,
    bool isTyping = false,
  }) {
    final bubbleColor = isUser ? const Color(0xFFFF9800) : Colors.white;
    final textColor = isUser ? Colors.white : const Color(0xFF111111);

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: isUser ? 80 : 0,
          end: isUser ? 0 : 80,
          bottom: 14,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(30), // ← ВСЕ стороны круглые
            boxShadow: [
              BoxShadow(
                color:
                    isUser ? const Color(0x55FF9800) : const Color(0x22000000),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isTyping
              ? const _TypingDots()
              : Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    height: 1.32,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMessages() {
    final display = [..._messages];

    if (_loading) {
      display.add({"role": "typing", "text": ""});
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      itemCount: display.length,
      itemBuilder: (_, i) {
        final msg = display[i];

        if (msg["role"] == "typing") {
          return _buildBubble(text: '', isUser: false, isTyping: true);
        }

        return _buildBubble(
          text: msg["text"] ?? "",
          isUser: msg["role"] == "user",
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(29),
              border: Border.all(
                color: const Color(0xCCFF9800),
                width: 1.45,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsetsDirectional.only(start: 18, end: 16),
            alignment: AlignmentDirectional.centerStart,
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => send(),
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Задайте вопрос про умру',
                hintStyle: TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _PremiumTap(
          onTap: send,
          child: Container(
            width: 92,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(29),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FF9800),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            alignment: AlignmentDirectional.center,
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 22, 0),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _buildModeSwitcher(),
                    const SizedBox(height: 26),
                    _buildHeroText(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildMessages(),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(22, 8, 22, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInputBar(),
                    const SizedBox(height: 10),
                    const Text(
                      'Модель обучена только для хаджа и умры',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF0F0F0),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PremiumTap({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PremiumTap> createState() => _PremiumTapState();
}

class _PremiumTapState extends State<_PremiumTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.86 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _a;
  late final Animation<double> _b;
  late final Animation<double> _c;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _a = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeInOut),
      ),
    );

    _b = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.73, curve: Curves.easeInOut),
      ),
    );

    _c = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 0.91, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(_a),
        const SizedBox(width: 6),
        _dot(_b),
        const SizedBox(width: 6),
        _dot(_c),
      ],
    );
  }
}
