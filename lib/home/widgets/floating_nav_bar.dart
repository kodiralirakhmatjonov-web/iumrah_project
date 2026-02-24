import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/home/home_page.dart';
import 'package:iumrah_project/home/in_umrah_page.dart';
import 'package:iumrah_project/home/after_umrah_page.dart';

class FloatingNavBar extends StatefulWidget {
  final int currentIndex;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  late int _index;

  final double _barWidth = 260;
  final double _barHeight = 60;

  double get _itemWidth => _barWidth / 3;

  @override
  void initState() {
    super.initState();
    _index = widget.currentIndex;
  }

  void _navigate(int index) {
    if (index == _index) return;

    setState(() => _index = index);

    Widget page;

    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const InUmrahPage();
        break;
      case 2:
        page = const AfterUmrahPage();
        break;
      default:
        page = const HomePage();
    }

    Navigator.of(context).pushAndRemoveUntil(
      PremiumRoute.push(page),
      (route) => false,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dx = details.localPosition.dx;

    final newIndex = (dx / _itemWidth).clamp(0, 2).floor();

    if (newIndex != _index) {
      setState(() => _index = newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: (_) => _navigate(_index),
          child: Container(
            width: _barWidth,
            height: _barHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
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
                // ===== Sliding Indicator =====
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  left: _index * _itemWidth,
                  child: Container(
                    width: _itemWidth,
                    height: _barHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),

                // ===== Icons =====
                Row(
                  children: [
                    _item(0, CupertinoIcons.chevron_left),
                    _item(1, CupertinoIcons.chevron_down),
                    _item(2, CupertinoIcons.chevron_right),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon) {
    final isActive = _index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _navigate(index),
        child: Center(
          child: Icon(
            icon,
            size: 26,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
