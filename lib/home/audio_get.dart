import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/widgets/green_wave.dart';
import 'package:iumrah_project/home/in_umrah_page.dart';

class AudioGetPage extends StatefulWidget {
  const AudioGetPage({super.key});

  @override
  State<AudioGetPage> createState() => _AudioGetPageState();
}

class _AudioGetPageState extends State<AudioGetPage>
    with TickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  // ---- ТВОЯ ЛОГИКА (НЕ ТРОНУТА) ----
  double _progress = 0;
  bool _done = false;
  String _status = "Preparing...";

  bool get _locked => !_done;

  late final AnimationController _blinkCtrl;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _blink = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );

    _blinkCtrl.repeat(reverse: true);

    _startDownload();
  }

  Future<void> _startDownload() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'ru';

    setState(() => _status = "Loading links...");

    final data = await Supabase.instance.client
        .from('audio')
        .select('key,url')
        .eq('lang', lang);

    if (data.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final client = HttpClient();

    int doneCount = 0;
    int total = data.length;

    for (final item in data) {
      final key = item['key'];
      final url = item['url'];

      final fileName = "${key}_$lang.mp3";
      final filePath = "${dir.path}/$fileName";
      final file = File(filePath);

      final prefKey = "audio_${key}_$lang";

      if (await file.exists()) {
        prefs.setString(prefKey, file.path);
        doneCount++;
        _updateProgress(doneCount, total);
        continue;
      }

      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);

        await file.writeAsBytes(bytes);
        prefs.setString(prefKey, file.path);
      } catch (_) {}

      doneCount++;
      _updateProgress(doneCount, total);
    }

    setState(() {
      _done = true;
      _status = "Offline available";
    });
  }

  void _updateProgress(int done, int total) {
    final p = done / total;
    setState(() {
      _progress = p;
      _status = "Downloading voice pack...";
    });
  }
  // ---- КОНЕЦ ТВОЕЙ ЛОГИКИ ----

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_locked) return;
    Navigator.of(context).push(PremiumRoute.push(const InUmrahPage()));
  }

  void _goBack() {
    if (_locked) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // HEADER
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
                const SizedBox(height: 18),

                Image.asset('assets/images/plus_image.png'),

                const SizedBox(height: 5),

                Text(
                  t('pay_text'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),

                const SizedBox(height: 25),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: const GreenWave(
                        expanded: true,
                      ),
                    ),
                    FadeTransition(
                      opacity: _blink,
                      child: Text(
                        t('advisor_text'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 30),

                Text(
                  t('plus_activ_text'),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),

                const SizedBox(height: 30),

                // LOADING CARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 63,
                        height: 63,
                        child: _done
                            ? const Icon(Icons.check_circle,
                                size: 63, color: Colors.green)
                            : const CupertinoActivityIndicator(radius: 30),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _done ? t('plus_activ_text3') : t('plus_activ_text2'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: SizedBox(
                          height: 35,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation(
                              _done ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("$percent%"),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Opacity(
                  opacity: _locked ? 0.4 : 1,
                  child: GestureDetector(
                    onTap: _goNext,
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF62FF00),
                            Color(0xFF007D06),
                          ],
                        ),
                      ),
                      child: Text(
                        t('plus_activ_btn2'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                const Text(
                  'Advisor',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  t('pay_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    fontSize: 36,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
