import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';

import 'package:iumrah_project/features/umrah/mydua_store.dart';
import 'package:iumrah_project/home/mydua_page.dart';

class MyDuaModal {
  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => const _MyDuaModalSheet(),
    );
  }
}

class _MyDuaModalSheet extends StatefulWidget {
  const _MyDuaModalSheet();

  @override
  State<_MyDuaModalSheet> createState() => _MyDuaModalSheetState();
}

class _MyDuaModalSheetState extends State<_MyDuaModalSheet> {
  String t(String key) => TranslationsStore.get(key);

  final MyDuaStore _store = MyDuaStore();

  void _openMyDuaPage() {
    Navigator.of(context).push(
      PremiumRoute.push(
        const MyDuaPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: FractionallySizedBox(
        heightFactor: 0.94,
        alignment: AlignmentDirectional.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(50),
              topEnd: Radius.circular(50),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // title
                Text(
                  t('home_btn3'),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: Colors.black87,
                    height: 1.05,
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: _store.notes,
                    builder: (_, notes, __) {
                      if (notes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t('modal_nodua'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                              const SizedBox(height: 24),
                              PremiumTap(
                                onTap: _openMyDuaPage,
                                child: Container(
                                  height: 60,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD7C24B),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    t('modal_adddua'),
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsetsDirectional.only(bottom: 8),
                        itemCount: notes.length,
                        itemBuilder: (_, index) {
                          return _ReadOnlyNoteCard(text: notes[index]);
                        },
                      );
                    },
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

class _ReadOnlyNoteCard extends StatelessWidget {
  final String text;

  const _ReadOnlyNoteCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: Container(
        height: 350,
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(24, 22, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            text.trim().isEmpty ? '—' : text,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
