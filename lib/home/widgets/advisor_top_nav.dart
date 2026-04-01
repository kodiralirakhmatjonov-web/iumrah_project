import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';

enum AdvisorMode {
  emotional,
  reading,
  chat,
}

class AdvisorTopNav extends StatefulWidget {
  final AdvisorMode current;
  final ValueChanged<AdvisorMode> onChanged;

  const AdvisorTopNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  State<AdvisorTopNav> createState() => _AdvisorTopNavState();
}

class _AdvisorTopNavState extends State<AdvisorTopNav> {
  double? _dragDx;
  bool _isDragging = false;

  AdvisorMode get _currentMode => widget.current;

  int _modeToIndex(AdvisorMode mode) {
    switch (mode) {
      case AdvisorMode.emotional:
        return 0;
      case AdvisorMode.reading:
        return 1;
      case AdvisorMode.chat:
        return 2;
    }
  }

  AdvisorMode _indexToMode(int index) {
    switch (index) {
      case 0:
        return AdvisorMode.emotional;
      case 1:
        return AdvisorMode.reading;
      default:
        return AdvisorMode.chat;
    }
  }

  void _handleTap(AdvisorMode mode) {
    if (mode == _currentMode) return;

    HapticFeedback.lightImpact();
    widget.onChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 48;

        final safeWidth = math.max(220.0, totalWidth);
        const outerPadding = 6.0;
        const navHeight = 66.0;

        final innerWidth = safeWidth - (outerPadding * 2);
        final segmentWidth = innerWidth / 3;

        final currentIndex = _modeToIndex(_currentMode);
        final snappedLeft = outerPadding + (segmentWidth * currentIndex);

        final minLeft = outerPadding;
        final maxLeft = outerPadding + innerWidth - segmentWidth;

        final currentLeft = _isDragging && _dragDx != null
            ? _dragDx!.clamp(minLeft, maxLeft)
            : snappedLeft;

        final dragCenter = currentLeft + (segmentWidth / 2);
        final dragIndex =
            ((dragCenter - outerPadding) / segmentWidth).round().clamp(0, 2);

        final pillScale = _isDragging ? 1.035 : 1.0;

        return SizedBox(
          width: safeWidth,
          height: navHeight,
          child: Stack(
            children: [
              Container(
                height: navHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFF08A1A),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF08A1A).withOpacity(0.08),
                      blurRadius: 18,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    _NavLabel(
                      text: 'emotional',
                      isActive: dragIndex == 0,
                      onTap: () => _handleTap(AdvisorMode.emotional),
                    ),
                    _NavLabel(
                      text: 'reading',
                      isActive: dragIndex == 1,
                      onTap: () => _handleTap(AdvisorMode.reading),
                    ),
                    _NavLabel(
                      text: 'ask Advisor',
                      isActive: dragIndex == 2,
                      onTap: () => _handleTap(AdvisorMode.chat),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: currentLeft,
                top: outerPadding,
                width: segmentWidth,
                height: navHeight - (outerPadding * 2),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isDragging = true;
                      _dragDx = snappedLeft;
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragDx = (currentLeft + details.delta.dx).clamp(
                        minLeft,
                        maxLeft,
                      );
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    final releasedCenter =
                        (_dragDx ?? snappedLeft) + (segmentWidth / 2);
                    final targetIndex =
                        ((releasedCenter - outerPadding) / segmentWidth)
                            .round()
                            .clamp(0, 2);
                    final targetMode = _indexToMode(targetIndex);

                    setState(() {
                      _isDragging = false;
                      _dragDx = null;
                    });

                    HapticFeedback.lightImpact();

                    if (targetMode != _currentMode) {
                      widget.onChanged(targetMode);
                    }
                  },
                  onHorizontalDragCancel: () {
                    setState(() {
                      _isDragging = false;
                      _dragDx = null;
                    });
                  },
                  child: AnimatedScale(
                    duration: _isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    scale: pillScale,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5A623).withOpacity(0.42),
                            blurRadius: 24,
                            spreadRadius: 1.5,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    _NavLabel(
                      text: 'emotional',
                      isActive: dragIndex == 0,
                      foregroundOnly: true,
                      onTap: () => _handleTap(AdvisorMode.emotional),
                    ),
                    _NavLabel(
                      text: 'reading',
                      isActive: dragIndex == 1,
                      foregroundOnly: true,
                      onTap: () => _handleTap(AdvisorMode.reading),
                    ),
                    _NavLabel(
                      text: 'ask Advisor',
                      isActive: dragIndex == 2,
                      foregroundOnly: true,
                      onTap: () => _handleTap(AdvisorMode.chat),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavLabel extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  final bool foregroundOnly;

  const _NavLabel({
    required this.text,
    required this.isActive,
    required this.onTap,
    this.foregroundOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      style: TextStyle(
        fontFamily: 'Lato',
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: foregroundOnly
            ? (isActive ? Colors.white : Colors.transparent)
            : (isActive ? Colors.transparent : Colors.white.withOpacity(0.92)),
        height: 1,
        letterSpacing: -0.2,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ),
    );

    return Expanded(
      child: PremiumTap(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: textWidget,
        ),
      ),
    );
  }
}
