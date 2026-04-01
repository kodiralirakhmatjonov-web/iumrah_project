import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';

class AboutProjectPage extends StatefulWidget {
  const AboutProjectPage({
    super.key,
    this.onSupportTap,
    this.onSponsorTap,
    this.onFollowTap,
  });

  final VoidCallback? onSupportTap;
  final VoidCallback? onSponsorTap;
  final VoidCallback? onFollowTap;

  @override
  State<AboutProjectPage> createState() => _AboutProjectPageState();
}

class _AboutProjectPageState extends State<AboutProjectPage>
    with SingleTickerProviderStateMixin {
  static const double _screenHPad = 24;
  static const double _cardPad = 20;
  static const double _mainGap = 40;
  static const double _radiusCard = 50;
  static const double _radiusButton = 50;
  static const double _buttonHeight = 60;

  static const Color _bg = Color(0xFFE6E6EF);
  static const Color _text = Color(0xFF111111);
  static const Color _muted = Color(0xFF6E6E73);
  static const Color _white = Colors.white;

  static const Color _heroDark = Color(0xFF0F0F14);
  static const Color _heroPurple = Color(0xFF610084);
  static const Color _heroPurpleSoft = Color(0xFFB354BE);
  static const Color _heroGold = Color(0xFFFFB347);
  static const Color _softPurpleBg = Color(0xFFF5ECF8);
  static const Color _softPurpleStroke = Color(0xFFE7DCF0);

  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  String t(String key, String fallback) {
    final value = TranslationsStore.get(key);
    if (value.trim().isEmpty || value == key) return fallback;
    return value;
  }

  void _showFallbackSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _text,
        content: Text(
          message,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: _white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleSupportTap() {
    HapticFeedback.mediumImpact();
    if (widget.onSupportTap != null) {
      widget.onSupportTap!();
      return;
    }

    _showFallbackSnack(
      t(
        'about_project_snack_support',
        'Сюда подключается донат, страница поддержки или внешний checkout.',
      ),
    );
  }

  void _handleSponsorTap() {
    HapticFeedback.mediumImpact();
    if (widget.onSponsorTap != null) {
      widget.onSponsorTap!();
      return;
    }

    _showFallbackSnack(
      t(
        'about_project_snack_sponsor',
        'Сюда подключается форма спонсорства, contact page или WhatsApp / email.',
      ),
    );
  }

  void _handleFollowTap() {
    HapticFeedback.mediumImpact();
    if (widget.onFollowTap != null) {
      widget.onFollowTap!();
      return;
    }

    _showFallbackSnack(
      t(
        'about_project_snack_follow',
        'Сюда подключается канал проекта, лист ожидания или страница обновлений.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
              colors: [
                Color(0xFFF7F7FB),
                Color(0xFFEDEDF4),
                Color(0xFFE6E6EF),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      _screenHPad,
                      8,
                      _screenHPad,
                      140,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: 16),
                        _buildValueCards(),
                        const SizedBox(height: _mainGap),
                        _buildWhySection(),
                        const SizedBox(height: 16),
                        _buildMissionSection(),
                        const SizedBox(height: 16),
                        _buildBuildingSection(),
                        const SizedBox(height: 16),
                        _buildSupportSection(),
                        const SizedBox(height: 16),
                        _buildSponsorSection(),
                        const SizedBox(height: _mainGap),
                        _buildFinalCtaCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            _screenHPad,
            0,
            _screenHPad,
            20,
          ),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: _white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PrimaryButton(
                    title: t(
                      'about_project_primary_cta',
                      'Поддержать проект',
                    ),
                    icon: Icons.favorite_rounded,
                    onTap: _handleSupportTap,
                    darkText: true,
                  ),
                ),
                const SizedBox(width: 10),
                _CircleActionButton(
                  icon: Icons.north_east_rounded,
                  onTap: _handleFollowTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        _screenHPad,
        12,
        _screenHPad,
        8,
      ),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t('about_project_page_title', 'О проекте'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final wave = math.sin(_ambientController.value * math.pi * 2);
        final wave2 = math.cos(_ambientController.value * math.pi * 2);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radiusCard),
            gradient: const LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                _heroDark,
                Color(0xFF161621),
                _heroPurple,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _heroPurple.withValues(alpha: 0.22),
                blurRadius: 36,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radiusCard),
            child: Stack(
              children: [
                PositionedDirectional(
                  top: -50 + (wave * 12),
                  end: -20 + (wave2 * 12),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _heroGold.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: _heroGold.withValues(alpha: 0.16),
                          blurRadius: 90,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: -70 + (wave2 * 10),
                  start: -40 + (wave * 10),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _heroPurpleSoft.withValues(alpha: 0.14),
                      boxShadow: [
                        BoxShadow(
                          color: _heroPurpleSoft.withValues(alpha: 0.16),
                          blurRadius: 110,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    _cardPad,
                    _cardPad,
                    _cardPad,
                    _cardPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          14,
                          8,
                          14,
                          8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          t('about_project_hero_badge', 'МИССИЯ IUMRAH'),
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: _white,
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t(
                          'about_project_hero_title',
                          'Больше, чем приложение',
                        ),
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t(
                          'about_project_hero_subtitle',
                          'iumrah создаётся ради одной цели: дать паломнику ясное, красивое и достойное сопровождение на одном из самых важных путей в его жизни.',
                        ),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 15,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          14,
                          14,
                          14,
                          14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Text(
                          t(
                            'about_project_hero_quote',
                            'Этот проект существует ради того, чтобы ни один паломник не чувствовал себя потерянным в священном пути.',
                          ),
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 14,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryButton(
                              title: t(
                                'about_project_primary_cta',
                                'Поддержать проект',
                              ),
                              icon: Icons.favorite_rounded,
                              onTap: _handleSupportTap,
                              darkText: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SecondaryButton(
                              title: t(
                                'about_project_secondary_cta',
                                'Стать спонсором',
                              ),
                              icon: Icons.volunteer_activism_rounded,
                              onTap: _handleSponsorTap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumns = constraints.maxWidth >= 760;
        final double itemWidth =
            twoColumns ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _MiniValueCard(
                icon: Icons.explore_rounded,
                title: t(
                  'about_project_value_1_title',
                  'Чёткое сопровождение',
                ),
                body: t(
                  'about_project_value_1_body',
                  'Не просто информация, а спокойный и понятный путь шаг за шагом.',
                ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MiniValueCard(
                icon: Icons.language_rounded,
                title: t(
                  'about_project_value_2_title',
                  'Больше языков',
                ),
                body: t(
                  'about_project_value_2_body',
                  'Чтобы guidance было доступно людям из разных стран, а не только узкому кругу.',
                ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MiniValueCard(
                icon: Icons.favorite_outline_rounded,
                title: t(
                  'about_project_value_3_title',
                  'Достойный опыт',
                ),
                body: t(
                  'about_project_value_3_body',
                  'Технология здесь служит не шуму, а уважению, ясности и внутреннему спокойствию.',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWhySection() {
    return _SectionCard(
      icon: Icons.lightbulb_outline_rounded,
      eyebrow: t(
        'about_project_why_eyebrow',
        'ПОЧЕМУ ЭТО ВООБЩЕ СУЩЕСТВУЕТ',
      ),
      title: t(
        'about_project_why_title',
        'Не каждому паломнику доступно качественное сопровождение',
      ),
      child: Text(
        t(
          'about_project_why_body',
          'Многие люди отправляются на умру с волнением, искренним намерением и большим ожиданием, но без действительно удобного, ясного и современного сопровождения. Кто-то сталкивается с языковым барьером. Кто-то теряется в последовательности действий. Кто-то просто хочет чувствовать спокойствие вместо стресса. iumrah создаётся, чтобы закрыть этот разрыв и сделать достойную помощь доступнее.',
        ),
        textAlign: TextAlign.start,
        style: const TextStyle(
          color: _muted,
          fontSize: 15,
          height: 1.65,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMissionSection() {
    return _SectionCard(
      icon: Icons.auto_awesome_rounded,
      eyebrow: t(
        'about_project_mission_eyebrow',
        'НАША МИССИЯ',
      ),
      title: t(
        'about_project_mission_title',
        'Построить новый стандарт цифрового сопровождения паломника',
      ),
      child: Text(
        t(
          'about_project_mission_body',
          'Мы хотим, чтобы guidance по умре стало более понятным, красивым, доступным и человечным. Не сухой инструкцией, не перегруженным сервисом, а продуктом, который действительно помогает пройти путь с ясностью и уважением к его духовной значимости. Это попытка соединить глубокий смысл паломничества и высокий уровень современного продукта.',
        ),
        textAlign: TextAlign.start,
        style: const TextStyle(
          color: _muted,
          fontSize: 15,
          height: 1.65,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBuildingSection() {
    return _SectionCard(
      icon: Icons.construction_rounded,
      eyebrow: t(
        'about_project_building_eyebrow',
        'ЧТО МЫ СТРОИМ СЕЙЧАС',
      ),
      title: t(
        'about_project_building_title',
        'Это уже не просто идея — это развивающийся продукт',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BulletLine(
            text: t(
              'about_project_building_item_1',
              'Пошаговое сопровождение умры, в котором пользователь не теряется в процессе.',
            ),
          ),
          const SizedBox(height: 12),
          _BulletLine(
            text: t(
              'about_project_building_item_2',
              'Поддержку нескольких языков, чтобы качественный опыт был доступен международной аудитории.',
            ),
          ),
          const SizedBox(height: 12),
          _BulletLine(
            text: t(
              'about_project_building_item_3',
              'Offline-first подход, чтобы помощь оставалась доступной даже тогда, когда связь нестабильна.',
            ),
          ),
          const SizedBox(height: 12),
          _BulletLine(
            text: t(
              'about_project_building_item_4',
              'Премиальный и спокойный пользовательский опыт, который ощущается достойно, а не случайно собранным.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return _SectionCard(
      icon: Icons.favorite_rounded,
      eyebrow: t(
        'about_project_support_eyebrow',
        'ПОЧЕМУ НУЖНА ПОДДЕРЖКА',
      ),
      title: t(
        'about_project_support_title',
        'Каждая поддержка ускоряет рост этой миссии',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'about_project_support_body',
              'Поддержка помогает не просто “содержать приложение”, а двигать вперёд саму идею: делать guidance лучше, расширять языки, улучшать качество контента и ускорять развитие функций, которые реально помогают паломникам.',
            ),
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: _muted,
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _SupportPoint(
            text: t(
              'about_project_support_point_1',
              'ускоряет добавление новых языков и расширение охвата',
            ),
          ),
          const SizedBox(height: 10),
          _SupportPoint(
            text: t(
              'about_project_support_point_2',
              'помогает улучшать voice guidance, тексты и пользовательский опыт',
            ),
          ),
          const SizedBox(height: 10),
          _SupportPoint(
            text: t(
              'about_project_support_point_3',
              'даёт проекту возможность расти не как MVP, а как серьёзной платформе',
            ),
          ),
          const SizedBox(height: 10),
          _SupportPoint(
            text: t(
              'about_project_support_point_4',
              'приближает момент, когда больше паломников получат действительно достойную поддержку',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorSection() {
    return _SectionCard(
      icon: Icons.handshake_rounded,
      eyebrow: t(
        'about_project_sponsor_eyebrow',
        'ДЛЯ СПОНСОРОВ И ПАРТНЁРОРОВ',
      ),
      title: t(
        'about_project_sponsor_title',
        'Поддержите не экран — поддержите будущее доступного сопровождения',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'about_project_sponsor_body',
              'Если вам близка идея сделать качественное сопровождение паломника доступнее, чище и современнее, вы можете стать частью этого роста. Спонсорство здесь — это вклад не только в продукт, но и в масштабную полезную миссию.',
            ),
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: _muted,
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _SecondaryLightButton(
            title: t(
              'about_project_secondary_cta',
              'Стать спонсором',
            ),
            icon: Icons.north_east_rounded,
            onTap: _handleSponsorTap,
          ),
        ],
      ),
    );
  }

  Widget _buildFinalCtaCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radiusCard),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF6F4FA),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        _cardPad,
        _cardPad,
        _cardPad,
        _cardPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'about_project_final_title',
              'Помогите этой миссии вырасти',
            ),
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: _text,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t(
              'about_project_final_body',
              'Даже одно действие уже важно: поддержать проект, рассказать о нём другим или стать спонсором его следующего шага.',
            ),
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: _muted,
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DarkButton(
                  title: t(
                    'about_project_primary_cta',
                    'Поддержать проект',
                  ),
                  icon: Icons.favorite_rounded,
                  onTap: _handleSupportTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryLightButton(
                  title: t(
                    'about_project_follow_cta',
                    'Следить за проектом',
                  ),
                  icon: Icons.arrow_forward_rounded,
                  onTap: _handleFollowTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5ECF8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF610084),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Color(0xFF7A5B8C),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _MiniValueCard extends StatelessWidget {
  const _MiniValueCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.88),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F0F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF610084),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Color(0xFF6E6E73),
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsetsDirectional.only(top: 7),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF610084),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: Color(0xFF4C4C52),
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportPoint extends StatelessWidget {
  const _SupportPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFF5ECF8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: Color(0xFF610084),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: Color(0xFF4C4C52),
              fontSize: 14.5,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF111111),
          size: 22,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.darkText = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: _AboutProjectPageState._buttonHeight,
        padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(_AboutProjectPageState._radiusButton),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  darkText ? const Color(0xFF111111) : const Color(0xFFFFFFFF),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: darkText
                      ? const Color(0xFF111111)
                      : const Color(0xFFFFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: _AboutProjectPageState._buttonHeight,
        padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius:
              BorderRadius.circular(_AboutProjectPageState._radiusButton),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryLightButton extends StatelessWidget {
  const _SecondaryLightButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: _AboutProjectPageState._buttonHeight,
        padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
        decoration: BoxDecoration(
          color: _AboutProjectPageState._softPurpleBg,
          borderRadius:
              BorderRadius.circular(_AboutProjectPageState._radiusButton),
          border: Border.all(
            color: _AboutProjectPageState._softPurpleStroke,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF610084),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Color(0xFF610084),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: _AboutProjectPageState._buttonHeight,
        padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius:
              BorderRadius.circular(_AboutProjectPageState._radiusButton),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F0F8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF610084),
          size: 22,
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.90 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
