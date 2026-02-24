import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/local_strings.dart';
import '../core/navigation/premium_route.dart';

class NoConnectionPage extends StatefulWidget {
  final Widget retryPage; // куда возвращаться

  const NoConnectionPage({super.key, required this.retryPage});

  @override
  State<NoConnectionPage> createState() => _NoConnectionPageState();
}

class _NoConnectionPageState extends State<NoConnectionPage> {
  String _lang = 'en';
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadLang();
    _listenConnection();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'en';
    });
  }

  void _listenConnection() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        Navigator.of(context).pushReplacement(
          PremiumRoute.push(widget.retryPage),
        );
      }
    });
  }

  Future<void> _retry() async {
    final result = await Connectivity().checkConnectivity();
    if (result != ConnectivityResult.none) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PremiumRoute.push(widget.retryPage),
        );
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/earth_bg.jpg', // твой фон
              fit: BoxFit.cover,
            ),
          ),

          /// Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    LocalStrings.t('no_connection_title', _lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(160, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      LocalStrings.t('retry_btn', _lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/images/iumrah_logo_bg.png',
                    height: 50,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
