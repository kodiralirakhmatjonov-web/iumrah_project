import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iumrah_project/features/language/reg_name.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/localization/local_strings.dart';
//import '../features/language/reg_form.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ================== PREMIUM DESIGN TOKENS (тот же шаблон) ==================
  static const double kBaseSpacing = 16;
  static const double kHPad = 24;
  static const double kMainVGap = 40;

  static const double kCardPad = 20;
  static const double kFieldGap = 12;

  static const double kRadiusCard = 50;
  static const double kRadiusField = 30;
  static const double kRadiusButton = 50;

  static const double kHField = 60;
  static const double kHButton = 65; // исключение для login/register

  static const Color kBg = Color(0xFFE6E6EF);
  static const Color kSoftText = Color(0xFF1B1B1F);
  static const Color kDisabled = Color(0xFFB9B9C3);
  static const Color kBlack = Color(0xFF000000);
  static const Color kDark = Color(0xFF2F2F2F);
  static const Color kFieldFill = Color(0xFFEAEAEA);
  static const Color kError = Color(0xFFDB3B3B);
  static const Color kOk = Color(0xFF39B54A);

  // ================== LANGUAGE ==================
  static const Set<String> _supportedLangs = {
    'ru',
    'uz',
    'kk',
    'id',
    'tr',
    'ms',
    'bn',
    'en',
    'fr',
  };

  String get lang {
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return _supportedLangs.contains(deviceLang) ? deviceLang : 'en';
  }

  // ================== CONTROLLERS ==================
  final _email = TextEditingController();
  final _pass = TextEditingController();

  // ================== UI STATES ==================
  bool _policyAccepted = false;
  bool _loading = false;

  bool _emailTouched = false;
  bool _emailValid = false;

  bool _submitted = false; // пароль красный только после submit
  bool _authError = false; // ошибка регистрации (email занят и т.п.)

  bool _obscure = true;

  bool get _canSubmit =>
      _emailValid &&
      _pass.text.trim().length >= 6 &&
      _policyAccepted &&
      !_loading;

  // ================== VALIDATION ==================
  void _onEmailChanged(String v) {
    final value = v.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

    setState(() {
      _emailTouched = true;
      _emailValid = ok;
      _authError = false;
    });
  }

  void _onPassChanged(String v) {
    setState(() {
      _authError = false;
    });
  }

  // ================== ACTIONS ==================
  Future<void> _openPolicy() async {
    HapticFeedback.selectionClick();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _PolicySheetStub(),
    );
  }

  Future<void> _register() async {
    setState(() {
      _submitted = true;
      _authError = false;
    });

    if (!_canSubmit) return;

    HapticFeedback.lightImpact();
    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pass.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        _premiumRoute(
          RegNamePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _authError = true);
      HapticFeedback.mediumImpact();
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Route _premiumRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        final offset = Tween<Offset>(
          begin: const Offset(0.02, 0.0),
          end: Offset.zero,
        ).animate(curve);

        return FadeTransition(
          opacity: curve,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final emailBorder = _emailTouched ? (_emailValid ? kOk : kError) : null;

    final passBorder =
        (_submitted && (_authError || _pass.text.trim().length < 6))
            ? kError
            : null;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: kHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: kMainVGap),

              // LOGO
              Center(
                child: Image.asset(
                  'assets/images/iumrah_logo.png',
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: kMainVGap),

              // SWITCHER (активна левая сторона - Registration)
              _PremiumAuthSwitcher(
                leftText: LocalStrings.t('register_title', lang),
                rightText: LocalStrings.t('login_title', lang),
                active: _AuthSide.left,
                onSwitchToLogin: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pushReplacement(
                    _premiumRoute(const LoginPage()),
                  );
                },
              ),

              const SizedBox(height: kMainVGap),

              // TITLES
              Text(
                '${LocalStrings.t('register_subtitle_1', lang)}\n'
                '${LocalStrings.t('register_subtitle_2', lang)}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: kSoftText,
                ),
              ),

              const SizedBox(height: kMainVGap),

              // WHITE CARD
              Container(
                padding: const EdgeInsets.all(kCardPad),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      offset: Offset(0, 10),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InputFieldPremium(
                      height: kHField,
                      icon: Icons.mail_outline,
                      hint: 'Email', // как ты сказал: можно оставить так
                      controller: _email,
                      obscure: false,
                      borderColor: emailBorder,
                      onChanged: _onEmailChanged,
                    ),
                    const SizedBox(height: kFieldGap),
                    _InputFieldPremium(
                      height: kHField,
                      icon: Icons.lock_outline,
                      hint: LocalStrings.t('register_password', lang),
                      controller: _pass,
                      obscure: _obscure,
                      borderColor: passBorder,
                      onChanged: _onPassChanged,
                      trailing: IconButton(
                        splashRadius: 22,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _obscure = !_obscure);
                        },
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF6B6B75),
                        ),
                      ),
                    ),
                    const SizedBox(height: kFieldGap),
                    _PolicyRow(
                      checked: _policyAccepted,
                      text: LocalStrings.t('login_policy_text', lang),
                      onToggle: () {
                        HapticFeedback.selectionClick();
                        setState(() => _policyAccepted = !_policyAccepted);
                      },
                      onOpenPolicy: _openPolicy,
                    ),
                    const SizedBox(height: kFieldGap),
                    _PremiumButton(
                      height: kHButton,
                      enabled: _canSubmit,
                      loading: _loading,
                      text: LocalStrings.t('register_continue', lang),
                      onTap: _register,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: kMainVGap),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== SWITCHER ==================

enum _AuthSide { left, right }

class _PremiumAuthSwitcher extends StatefulWidget {
  final String leftText;
  final String rightText;
  final _AuthSide active;
  final VoidCallback onSwitchToLogin;

  const _PremiumAuthSwitcher({
    required this.leftText,
    required this.rightText,
    required this.active,
    required this.onSwitchToLogin,
  });

  @override
  State<_PremiumAuthSwitcher> createState() => _PremiumAuthSwitcherState();
}

class _PremiumAuthSwitcherState extends State<_PremiumAuthSwitcher> {
  double _dragT = 0.0; // 0..1 (0 = left, 1 = right)

  @override
  void initState() {
    super.initState();
    _dragT = widget.active == _AuthSide.right ? 1.0 : 0.0;
  }

  void _commitIfNeeded() {
    // Если утащили вправо - уходим на login
    if (_dragT > 0.5) {
      widget.onSwitchToLogin();
    } else {
      setState(() => _dragT = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const height = 65.0;
    const radiusOuter = 50.0;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final knobW = w / 2;

        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            final dx = d.delta.dx;
            final deltaT = dx / knobW;
            setState(() => _dragT = (_dragT + deltaT).clamp(0.0, 1.0));
          },
          onHorizontalDragEnd: (_) {
            HapticFeedback.selectionClick();
            _commitIfNeeded();
          },
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radiusOuter),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 14,
                  offset: Offset(0, 8),
                  color: Color(0x12000000),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: _dragT * knobW,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: knobW,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F2F2F),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(radiusOuter),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _dragT = 0.0);
                        },
                        child: Center(
                          child: Text(
                            widget.leftText,
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _dragT < 0.5
                                  ? Colors.white
                                  : Colors.black.withOpacity(0.35),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(radiusOuter),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onSwitchToLogin();
                        },
                        child: Center(
                          child: Text(
                            widget.rightText,
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _dragT > 0.5
                                  ? Colors.white
                                  : Colors.black.withOpacity(0.35),
                            ),
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
}

// ================== INPUT ==================

class _InputFieldPremium extends StatelessWidget {
  final double height;
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final Color? borderColor;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  const _InputFieldPremium({
    required this.height,
    required this.icon,
    required this.hint,
    required this.controller,
    required this.obscure,
    this.borderColor,
    this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: _RegisterPageState.kFieldFill,
        borderRadius: BorderRadius.circular(_RegisterPageState.kRadiusField),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.4)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5E5E66)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontSize: 16,
                color: _RegisterPageState.kSoftText,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 16,
                  color: Color(0xFF8C8C96),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ================== POLICY ROW ==================

class _PolicyRow extends StatelessWidget {
  final bool checked;
  final String text;
  final VoidCallback onToggle;
  final VoidCallback onOpenPolicy;

  const _PolicyRow({
    required this.checked,
    required this.text,
    required this.onToggle,
    required this.onOpenPolicy,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onToggle,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFE6E6EF),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _CheckCircle(checked: checked),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpenPolicy,
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 12.5,
                    height: 1.1,
                    color: Color(0xFF6B6B75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool checked;

  const _CheckCircle({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? const Color(0xFF2ECC71) : const Color(0xFFD9D9DF),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: 16,
        color: checked ? Colors.white : const Color(0xFF8E8E98),
      ),
    );
  }
}

// ================== PREMIUM BUTTON ==================

class _PremiumButton extends StatefulWidget {
  final double height;
  final bool enabled;
  final bool loading;
  final String text;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.height,
    required this.enabled,
    required this.loading,
    required this.text,
    required this.onTap,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.enabled
        ? _RegisterPageState.kBlack
        : _RegisterPageState.kDisabled;
    final opacity = widget.enabled ? 1.0 : 0.55;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.enabled || widget.loading) return;
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        if (!widget.enabled || widget.loading) return;
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: _pressed ? (opacity * 0.92) : opacity,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  BorderRadius.circular(_RegisterPageState.kRadiusButton),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(0, 10),
                  color: Color(0x18000000),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CupertinoActivityIndicator(
                      radius: 15,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  )
                : Text(
                    widget.text,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ================== POLICY (stub) ==================

class _PolicySheetStub extends StatelessWidget {
  const _PolicySheetStub();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: math.min(h * 0.72, 1020),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(50),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==== GRABBER ====
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E2EA),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "iumrah project Privacy Policy",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  '''
Developer: Aziz Kodirov / iumrah project
Contact: iumrahproject@gmail.com
Country: Saudi Arabia
1. General Information
This application iumrah project (“App”) respects your privacy.
This Privacy Policy explains what data we collect, how we use it, and how we protect it.
By using the App, you agree to this Privacy Policy.

2. Data Collection and Use
The App may collect and process the following information:
 • Name, email address, phone number (for communication or registration);
 • Geolocation (if navigation or SOS features are used);
 • Technical data (device type, OS version, language, country);
 • Data provided via Google Sheets (e.g., feedback forms or usage statistics).

Note: All bookings and payments are processed through embedded WebView services:
Aviasales (flights) and Agoda (hotels).
The App does not store or process any payment card data — all transactions occur directly on those third-party platforms.

3. Purpose of Data Processing
Collected data is used for:
 • providing App services;
 • operating the voice guide and customizing user experience;
 • user support and app improvement;
 • ensuring user safety during pilgrimage;
 • managing paid subscriptions and donation records.

4. Subscriptions and Donations
The App offers an annual voice guide subscription and allows donations through the App Store or Google Play.
All donations are used solely for server maintenance, operational costs, and the development of global pilgrimage technologies.

5. Third-Party Services
The App may use the following external services:
 • Aviasales and Agoda – for bookings and payments;
 • Google Sheets – for data management;
 • Google Maps – for navigation;
 • AI Voice Engine – for the voice guide.

Each third-party service has its own privacy policy that applies to its data handling.

6. Data Storage and Protection
We take all reasonable measures to protect user data from loss, unauthorized access, or alteration.
All data is stored securely and never shared with third parties unless required for service functionality.

7. User Rights
Users have the right to:
 • request deletion or modification of their data;
 • cancel subscriptions and delete the App;
 • contact us for any privacy-related questions at iumrahproject@gmail.com.

8. Policy Updates
We may update this Policy from time to time. Any changes will be posted in the App and on our official website.

9. Contact
For questions regarding privacy, please contact us at:
📧 iumrahproject@gmail.com
''',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),
                const Text(
                  "ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ iumrah project",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  '''
Разработчик: Aziz Kodirov / iumrah project
Контакт: iumrahproject@gmail.com
Страна: Саудовская Аравия | Узбекистан
1. Общие положения
Данное приложение iumrah project (далее — «Приложение») уважает право пользователей на конфиденциальность. Настоящая Политика описывает, какие данные мы собираем, как их используем и как обеспечиваем их защиту.

Используя Приложение, вы соглашаетесь с условиями данной Политики.

2. Сбор и использование данных
Приложение может собирать и обрабатывать следующие данные:
 • Имя, адрес электронной почты, номер телефона (при регистрации или обратной связи);
 • Геолокация (если пользователь активирует навигационные функции или SOS-сервис);
 • Техническая информация о устройстве (тип устройства, версия ОС, язык, страна);
 • Данные, предоставляемые через Google Sheets (например, форма обратной связи или статистика).

Важно: все бронирования и оплаты происходят через встроенные вебвью-сервисы —
Aviasales (авиабилеты) и Agoda (отели).
Приложение не хранит и не обрабатывает данные платежных карт — они обрабатываются только на стороне указанных сервисов.

3. Цель обработки данных
Собранные данные используются исключительно для:
 • предоставления сервисов Приложения;
 • работы голосового гида и персонализации контента;
 • поддержки пользователей и улучшения функциональности;
 • обеспечения безопасности пользователей во время паломничества;
 • администрирования платной подписки и учёта донатов.

4. Подписки и донаты
Приложение предлагает годовую подписку на голосовой гид и возможность делать донаты через App Store / Google Play.
Донаты используются исключительно для покрытия расходов на серверы, техническое обслуживание и развитие технологий паломничества.

5. Передача данных третьим лицам
Приложение может использовать сторонние сервисы:
 • Aviasales и Agoda — для бронирований и оплаты;
 • Google Sheets — для хранения базовых данных;
 • Google Maps — для карт и навигации;
 • ИИ-озвучка (AI Voice) — для работы голосового гида.

Эти сервисы могут обрабатывать данные в соответствии со своими собственными политиками конфиденциальности.

6. Хранение и защита данных
Мы принимаем все разумные меры для защиты данных пользователей от утраты, несанкционированного доступа и изменения.
Данные хранятся только на защищённых серверах сторонних поставщиков и не передаются третьим лицам без необходимости.

7. Права пользователей
Пользователь имеет право:
 • запросить удаление или изменение своих данных;
 • отказаться от подписки и удалить приложение;
 • связаться с нами для любых вопросов по адресу: iumrahproject@gmail.com

8. Изменения политики
Мы можем обновлять данную Политику. Новая версия будет опубликована в приложении и на сайте.

9. Контактная информация
По вопросам конфиденциальности обращайтесь на email:
📧 iumrahproject@gmail.com
''',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
