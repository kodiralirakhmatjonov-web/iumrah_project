import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.logoHeight = 85,
    this.buttonSize = 50,
    this.iconSize = 30,
    this.isDarkBackground = true,
    this.onBack,
  });

  final double logoHeight;
  final double buttonSize;
  final double iconSize;
  final bool isDarkBackground;
  final VoidCallback? onBack;

  String get _logoAsset {
    return isDarkBackground
        ? 'assets/images/iumrah_logo.png'
        : 'assets/images/iumrah_logo1.png';
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          _logoAsset,
          height: logoHeight,
          fit: BoxFit.contain,
        ),
        GestureDetector(
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
          child: Container(
            height: buttonSize,
            width: buttonSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
              size: iconSize,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
