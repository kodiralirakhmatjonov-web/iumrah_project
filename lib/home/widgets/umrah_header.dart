import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/home/home_page.dart';
import 'package:iumrah_project/home/modal/policy_modal.dart';

import 'package:iumrah_project/home/safa_page.dart';
import 'package:iumrah_project/home/umrah_end.dart';
import 'package:iumrah_project/home/umrah_page.dart';
import 'package:iumrah_project/home/umrah_start..dart';

import 'package:iumrah_project/home/tawaf_page.dart';

class UmrahHeader extends StatelessWidget {
  final int currentStep;

  const UmrahHeader({
    super.key,
    required this.currentStep,
  });

  String t(String key) => TranslationsStore.get(key);

  String _getLogo() {
    if (currentStep == 0 || currentStep == 4) {
      return 'assets/images/iumrah_logo1.png';
    } else {
      return 'assets/images/iumrah_logo.png';
    }
  }

  // ================= SAFARI =================
  void _openSafariModal(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const PolicyModal(),
    );
  }

  // ================= PICKER =================
  void _openStepPicker(BuildContext context) {
    HapticFeedback.mediumImpact();

    final items = [
      t('umrah_start_title'),
      t('tawaf_title'),
      t('tawaf_break_title'),
      t('sai_title'),
      t('tahallul_title'),
    ];

    int selectedIndex = currentStep;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                          initialItem: selectedIndex),
                      itemExtent: 44,
                      useMagnifier: true,
                      magnification: 1.1,
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          selectedIndex = index;
                        });
                      },
                      children: items
                          .map(
                            (e) => Center(
                              child: Text(
                                e,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        PremiumTap(
                          onTap: () {
                            Navigator.pop(context);

                            Widget page;

                            switch (selectedIndex) {
                              case 0:
                                page = const UmrahStartPage();
                                break;
                              case 1:
                                page = const TawafPage();
                                break;
                              case 2:
                                page = const UmrahPage();
                                break;
                              case 3:
                                page = const SafaPage();
                                break;
                              case 4:
                                page = const UmrahEndPage();
                                break;
                              default:
                                page = const UmrahStartPage();
                            }

                            Navigator.of(context).pushReplacement(
                              PremiumRoute.push(page),
                            );
                          },
                          child: Container(
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF06D13),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(t('navigate_button')),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PremiumTap(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(t('close_button')),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PremiumTap(
                          onTap: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              PremiumRoute.push(const HomePage()),
                              (route) => false,
                            );
                          },
                          child: Container(
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              t('cancel_omra'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PremiumTap(
          onTap: () => _openSafariModal(context),
          child: Image.asset(
            _getLogo(),
            height: 85,
          ),
        ),
        PremiumTap(
          onTap: () => _openStepPicker(context),
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
    );
  }
}
