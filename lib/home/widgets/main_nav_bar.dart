import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/hajj/main_home_page.dart';

import 'package:iumrah_project/home/advisor_home.dart';
import 'package:iumrah_project/home/in_umrah_page.dart';
import 'package:iumrah_project/home/after_umrah_page.dart';

class MainNavBar extends StatefulWidget {
  final int currentIndex;

  const MainNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar>
    with SingleTickerProviderStateMixin {
  late int _index;

  final double barWidth = 260;
  final double barHeight = 60;

  double get itemWidth => barWidth / 3;

  double get fixedItemWidth => barWidth / 3;

  double dragX = 0;
  bool isDragging = false;

  // ✅ ДОБАВЛЕНО
  final GlobalKey _indicatorKey = GlobalKey();
  final GlobalKey _advisorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _index = widget.currentIndex.clamp(0, 3);
    if (_index < 0) _index = 0;
    if (_index > 2) _index = 2;

    dragX = _index * itemWidth;
  }

  void navigate(int index) {
    Widget page;

    if (index == 0) {
      page = const MainHomePage();
    } else if (index == 1) {
      page = const InUmrahPage();
    } else {
      page = const AfterUmrahPage();
    }

    Navigator.of(context).pushAndRemoveUntil(
      PremiumRoute.push(page),
      (route) => false,
    );
  }

  void onDragStart(DragStartDetails details) {
    isDragging = true;
  }

  void onDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragX += details.delta.dx;

      if (dragX < 0) dragX = 0;
      if (dragX > barWidth - itemWidth) {
        dragX = barWidth - itemWidth;
      }
    });
  }

  void onDragEnd(DragEndDetails details) {
    int newIndex = (dragX / itemWidth).round();

    if (newIndex < 0) newIndex = 0;
    if (newIndex > 2) newIndex = 2;

    setState(() {
      _index = newIndex;
      dragX = newIndex * itemWidth;
      isDragging = false;
    });

    navigate(newIndex);
  }

  // ✅ АНИМАЦИЯ ПЕРЕЛЁТА
  Future<void> animateToAdvisor(BuildContext context) async {
    final overlay = Overlay.of(context);

    final indicatorBox =
        _indicatorKey.currentContext?.findRenderObject() as RenderBox?;
    final advisorBox =
        _advisorKey.currentContext?.findRenderObject() as RenderBox?;

    if (indicatorBox == null || advisorBox == null) return;

    final start = indicatorBox.localToGlobal(Offset.zero);
    final end = advisorBox.localToGlobal(Offset.zero);

    final size = indicatorBox.size;

    late OverlayEntry entry;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            final dx = lerpDouble(start.dx, end.dx, animation.value)!;
            final dy = lerpDouble(start.dy, end.dy, animation.value)!;
            final scale = lerpDouble(1.0, 0.85, animation.value)!;

            return Positioned(
              left: dx,
              top: dy,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withOpacity(0.2),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose(); // ✅ важно
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: onDragStart,
                onHorizontalDragUpdate: onDragUpdate,
                onHorizontalDragEnd: onDragEnd,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: barWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                            color: Colors.black.withOpacity(0.12),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: isDragging
                                ? Duration.zero
                                : const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            left: dragX,
                            child: AnimatedContainer(
                              key: _indicatorKey,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              width: itemWidth,
                              height: barHeight,
                              transform: Matrix4.identity()
                                ..scale(isDragging ? 1.05 : 1.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                    color: Colors.black.withOpacity(0.10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: barWidth,
                            height: barHeight,
                            child: Row(
                              children: [
                                item(0, CupertinoIcons.house_fill),
                                item(1, CupertinoIcons.person_2_fill),
                                item(2, CupertinoIcons.person_crop_circle_fill),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                key: _advisorKey,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).push(
                    PremiumRoute.push(const AdvisorHomePage()),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 85,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(0.12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Advisor",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            height: 1.1,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget item(int index, IconData icon) {
    bool isActive = _index == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => navigate(index),
      child: SizedBox(
        width: itemWidth,
        height: barHeight,
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            scale: isActive ? 1.15 : 1.0,
            child: Icon(
              icon,
              size: 26,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
