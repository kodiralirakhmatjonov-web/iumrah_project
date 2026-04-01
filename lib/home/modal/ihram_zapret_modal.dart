import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';

Future<void> showIhramRestrictionsModal(
  BuildContext context, {
  VoidCallback? onAcknowledge,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.50),
    builder: (_) {
      return IhramRestrictionsModal(
        onAcknowledge: onAcknowledge,
      );
    },
  );
}

class IhramRestrictionsModal extends StatelessWidget {
  const IhramRestrictionsModal({
    super.key,
    this.onAcknowledge,
  });
  String t(String key) => TranslationsStore.get(key);
  final VoidCallback? onAcknowledge;

  static const double _topRadius = 50;
  static const double _contentHPad = 24;
  static const double _buttonHeight = 60;

  static const Color _white = Colors.white;
  static const Color _crossColor = Color(0xFFFF7467);
  static const Color _sheetStroke = Color(0xFFFF8A7E);
  static const Color _buttonColor = Color(0xFFFF5A1F);
  static const Color _footerText = Color(0xFFF8D8D4);

  void _close(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    onAcknowledge?.call();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double sheetHeight = media.size.height * 0.90;
    final double bottomSafe = media.padding.bottom;

    return SizedBox(
      height: sheetHeight,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 249, 21, 9)
                          .withValues(alpha: 0.16),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(_topRadius),
                topEnd: Radius.circular(_topRadius),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(_topRadius),
                topEnd: Radius.circular(_topRadius),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18,
                        sigmaY: 18,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(255, 167, 17, 1)
                              .withValues(alpha: 0.42),
                          width: 1.2,
                        ),
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topCenter,
                          end: AlignmentDirectional.bottomCenter,
                          colors: [
                            const Color.fromARGB(255, 149, 40, 0)
                                .withValues(alpha: 0.95),
                            const Color(0xFFF26E57).withValues(alpha: 0.94),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    bottom: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsetsDirectional.fromSTEB(
                        _contentHPad,
                        20,
                        _contentHPad,
                        bottomSafe + 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _Pressable(
                            onTap: () => _close(context),
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 40,
                                color: _crossColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            t('ihramzapret_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 23,
                              height: 1.10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            t(
                              'ihramzapret_subtitle',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 18,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _RuleRow(
                            text: t('ihramzapret_box1'),
                          ),
                          const SizedBox(height: 8),
                          _RuleRow(
                            text: t('ihramzapret_box2'),
                          ),
                          const SizedBox(height: 8),
                          _RuleRow(
                            text: t('ihramzapret_box3'),
                          ),
                          const SizedBox(height: 8),
                          _RuleRow(
                            text: t('ihramzapret_box4'),
                          ),
                          const SizedBox(height: 8),
                          _RuleRow(
                            text: t('ihramzapret_box5'),
                          ),
                          const SizedBox(height: 24),
                          _SectionLabel(
                            text: t('ihramzapret_box6'),
                          ),
                          const SizedBox(height: 14),
                          _RuleRow(
                            text: t('ihramzapret_box6'),
                          ),
                          const SizedBox(height: 8),
                          _RuleRow(
                            text: t('ihramzapret_box1'),
                          ),
                          const SizedBox(height: 24),
                          _SectionLabel(
                            text: t('ihramzapret_box1'),
                          ),
                          const SizedBox(height: 14),
                          _RuleRow(
                            text: t('ihramzapret_box1'),
                          ),
                          const SizedBox(height: 26),
                          _DangerButton(
                            title: t('close_btn'),
                            onTap: () => _close(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('home1_btn3_sub'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _footerText,
                              fontSize: 11.5,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1.12,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 1),
          child: Icon(
            Icons.close_rounded,
            size: 24,
            color: const Color.fromARGB(255, 163, 0, 0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 191, 51, 0),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color:
                  const Color.fromARGB(255, 255, 0, 0).withValues(alpha: 0.34),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: AlignmentDirectional.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
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
          scale: _pressed ? 0.976 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
