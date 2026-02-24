import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/features/umrah/mydua_store.dart';

class MyDuaPage extends StatefulWidget {
  const MyDuaPage({super.key});

  @override
  State<MyDuaPage> createState() => _MyDuaPageState();
}

class _MyDuaPageState extends State<MyDuaPage>
    with SingleTickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  int _phase = 0;
  Timer? _timer;

  final MyDuaStore _store = MyDuaStore();

  // ✅ for full page scroll + keyboard stability
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _phase = _phase == 0 ? 1 : 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _phase == 0 ? t('home_btn3') : t('mydua_subtitle');
    final text = _phase == 0 ? t('mydua_text') : t('mydua_text1');

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            // ЗОЛОТОЙ СВЕТ
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.4),
                    radius: 0.6,
                    colors: [
                      Color(0xFFFFDA07),
                      Color(0x00FFDA07),
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 29),
                // ✅ FULL PAGE SCROLL (all elements)
                child: CustomScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    // TOP
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                'assets/images/iumrah_logo1.png',
                                height: 85,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
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
                          ),
                          const SizedBox(height: 40),

                          // ✅ FIXED HEIGHT TEXT BLOCK (so notes don't move)
                          SizedBox(
                            height:
                                290, // фиксируем, чтобы карточки не дергались
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(seconds: 1),
                                child: Column(
                                  key: ValueKey(_phase),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),

                    // NOTES LIST (part of full scroll)
                    SliverToBoxAdapter(
                      child: ValueListenableBuilder(
                        valueListenable: _store.notes,
                        builder: (_, List<String> notes, __) {
                          if (notes.isEmpty) return const SizedBox.shrink();

                          return Column(
                            children: List.generate(notes.length, (index) {
                              return _NoteCard(
                                key: ValueKey('note_$index'), // ✅ stable key
                                scrollController: _scrollController,
                                text: notes[index],
                                onChanged: (v) => _store.update(index, v),
                                onDelete: () => _store.remove(index),
                              );
                            }),
                          );
                        },
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ADD BUTTON
                    SliverToBoxAdapter(
                      child: Align(
                        alignment: AlignmentDirectional.center,
                        child: GestureDetector(
                          onTap: () => _store.add(),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 36,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ✅ extra bottom padding so keyboard doesn't kill the last field
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 24 + MediaQuery.of(context).viewInsets.bottom,
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

class _NoteCard extends StatefulWidget {
  final String text;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  final ScrollController scrollController;

  const _NoteCard({
    super.key,
    required this.text,
    required this.onChanged,
    required this.onDelete,
    required this.scrollController,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode = FocusNode();

    // ✅ ensure focused field stays visible with keyboard
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        HapticFeedback.selectionClick();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Scrollable.ensureVisible(
            context,
            alignment: 0.35,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ do NOT reset controller while user is typing (prevents focus drop)
    if (!_focusNode.hasFocus && widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Dismissible(
        // ✅ stable key comes from widget.key (ValueKey('note_$index'))
        key: widget.key ?? UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => widget.onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            CupertinoIcons.delete,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: Container(
          // ✅ minimum size like you asked earlier (kept stable for UX)
          constraints: const BoxConstraints(minHeight: 350),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: _controller,
            maxLines: null,
            // ✅ bigger input text for older users
            style: const TextStyle(
              fontFamily: 'Lato',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            // ✅ keeps field visible above keyboard
            scrollPadding: const EdgeInsets.only(bottom: 220),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
