// lib/features/plus/plus_page.dart
//
// ✅ UI НЕ ТРОНУТ: структура/виджеты/цвета/размеры/тексты 1:1 как ты дал.
// ✅ Продакшн-архитектура покупки:
//    - фильтрация purchaseStream по productID
//    - защита от double tap / race
//    - completePurchase СРАЗУ (чтобы не зависать в pending при плохом интернете)
//    - offline-first: prefs -> true сразу, Supabase sync best-effort + флаг premium_needs_sync
//    - restore purchases
//    - безопасные mounted checks
//
// ⚠️ ТЕБЕ НУЖНО:
// 1) productId в kAdvisorProductId должен совпадать с App Store / Play Console
// 2) profiles.is_premium boolean в Supabase
// 3) (опционально) добавить точный переход на AudioGetPage в _openAudioGetOrSuccess()
//    сейчас fallback: PlusActivModal (как у тебя было)
//
// NOTE: Локализация: TranslationsStore.get(key) — не трогаю.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/home/audio_get.dart';
import 'package:iumrah_project/widgets/green_wave.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';

// ✅ модалка поздравления (как было)

class PlusPage extends StatefulWidget {
  const PlusPage({super.key});

  @override
  State<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> {
  String t(String key) => TranslationsStore.get(key);

  // =========================
  // IAP CONFIG
  // =========================
  static const String kAdvisorProductId =
      'iumrah.plus'; // <-- ВСТАВЬ СВОЙ PRODUCT ID

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  ProductDetails? _product;
  bool _storeAvailable = false;

  // UI state
  bool _loadingPurchase = false;

  // Internal guard: protects against double tap / re-entrancy
  bool _purchaseInFlight = false;

  @override
  void initState() {
    super.initState();
    _initIap();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _initIap() async {
    final available = await _iap.isAvailable();
    if (!mounted) return;

    setState(() => _storeAvailable = available);
    if (!available) return;

    // Subscribe BEFORE querying products — correct flow for StoreKit / Play Billing
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) {
        debugPrint('purchaseStream error: $e');
        if (!mounted) return;
        _endLoadingWithMessage('Purchase error');
      },
    );

    final resp = await _iap.queryProductDetails({kAdvisorProductId});
    if (!mounted) return;

    if (resp.error != null) {
      debugPrint('queryProductDetails error: ${resp.error}');
      // Store is available, but product query failed — keep UI usable
      return;
    }

    if (resp.productDetails.isEmpty) {
      debugPrint('No productDetails found for $kAdvisorProductId');
      return;
    }

    setState(() => _product = resp.productDetails.first);
  }

  // =========================
  // BUY
  // =========================
  Future<void> _buyAdvisor() async {
    HapticFeedback.lightImpact();

    // Hard guard first (prevents race on double tap)
    if (_purchaseInFlight) return;
    _purchaseInFlight = true;

    // Start loading immediately (no gap window)
    if (mounted) {
      setState(() => _loadingPurchase = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyPremium = prefs.getBool('ispremium') ?? false;
      if (alreadyPremium) {
        if (!mounted) return;
        _loadingPurchase = false;
        _purchaseInFlight = false;
        // already premium -> go success/audio-get
        _openAudioGetOrSuccess();
        return;
      }

      if (!_storeAvailable || _product == null) {
        _endLoadingWithMessage('Store not ready');
        return;
      }

      final purchaseParam = PurchaseParam(productDetails: _product!);

      // Non-consumable (one-time purchase)
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      // After this, purchaseStream will deliver updates.
      // Do not end loading here.
    } catch (e) {
      debugPrint('_buyAdvisor error: $e');
      _endLoadingWithMessage('Purchase failed');
    }
  }

  // =========================
  // PURCHASE STREAM HANDLER
  // =========================
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // ✅ CRITICAL: filter only our product
      if (purchase.productID != kAdvisorProductId) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (mounted) setState(() => _loadingPurchase = true);
          break;

        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchase.error}');
          _endLoadingWithMessage('Purchase failed');
          break;

        case PurchaseStatus.canceled:
          _endLoadingWithMessage('Canceled');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchase);
          break;
      }
    }
  }

  // =========================
  // SUCCESS: COMPLETE FIRST -> PREFS -> SYNC SUPABASE (best-effort) -> NAV
  // =========================
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      // 1) ✅ COMPLETE PURCHASE FIRST
      // This prevents "stuck pending" loops if network is bad during DB calls.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      // 2) ✅ LOCAL PREMIUM FIRST (offline-first)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ispremium', true);
      // Mark that server sync may be needed (we'll clear if sync ok)
      await prefs.setBool('premium_needs_sync', true);

      // 3) ✅ BEST-EFFORT SUPABASE SYNC (do not block user)
      await _syncPremiumToSupabaseBestEffort(prefs);

      if (!mounted) return;

      setState(() => _loadingPurchase = false);
      _purchaseInFlight = false;

      // 4) ✅ OPEN AudioGet (or success modal fallback)
      _openAudioGetOrSuccess();
    } catch (e) {
      debugPrint('handleSuccessfulPurchase error: $e');
      // Even if we fail here, we still try to avoid leaving UI locked
      if (!mounted) return;
      setState(() => _loadingPurchase = false);
      _purchaseInFlight = false;
      _toast('Activation error');
    }
  }

  Future<void> _syncPremiumToSupabaseBestEffort(SharedPreferences prefs) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        // User not logged in: keep premium locally and sync later on login/app start
        return;
      }

      await supabase
          .from('profiles')
          .update({'is_premium': true}).eq('id', user.id);

      // If succeeded, clear "needs sync"
      await prefs.setBool('premium_needs_sync', false);
    } catch (e) {
      debugPrint('_syncPremiumToSupabaseBestEffort error: $e');
      // Keep premium_needs_sync = true
    }
  }

  // =========================
  // RESTORE
  // =========================
  Future<void> _restorePurchases() async {
    HapticFeedback.lightImpact();

    if (!_storeAvailable) return;
    if (_purchaseInFlight) return;

    _purchaseInFlight = true;
    if (mounted) setState(() => _loadingPurchase = true);

    try {
      await _iap.restorePurchases();
      // purchaseStream will handle restored items (filtered by productId)
    } catch (e) {
      debugPrint('_restorePurchases error: $e');
      _endLoadingWithMessage('Restore failed');
    }
  }

  // =========================
  // NAV / SUCCESS
  // =========================
  void _openAudioGetOrSuccess() {
    if (!mounted) return;

    Navigator.of(context).push(
      PremiumRoute.push(
        const AudioGetPage(),
      ),
    );
  }

  void _endLoadingWithMessage(String msg) {
    if (!mounted) return;
    setState(() => _loadingPurchase = false);
    _purchaseInFlight = false;
    _toast(msg);
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =========================
  // UI (визуал: НЕ ТРОГАЕМ)
  // =========================
  @override
  Widget build(BuildContext context) {
    // ✅ статус-бар видимый
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // CONTENT
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(30, 10, 30, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ===== HEADER (logo + back) =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/iumrah_logo1.png',
                            height: 85,
                            fit: BoxFit.contain,
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: AlignmentDirectional.center,
                              child: const Icon(
                                CupertinoIcons.chevron_back,
                                size: 30,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ===== IMAGE advisor.png =====
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/plus_image.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===== GREEN WAVE вместо зелёного прямоугольника =====
                      // Текст поверх анимации: advisor_text
                      Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 170,
                              child: const GreenWave(
                                expanded: true,
                              ), // <-- твоя анимация
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                25, 0, 25, 0),
                            child: Text(
                              t('advisor_text'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ===== BIG TEXT pay_text =====
                      Text(
                        t('pay_text'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ===== CHECKLIST (pay_box...) =====
                      _CheckRow(text: t('pay_box')),
                      const SizedBox(height: 10),
                      _CheckRow(text: t('pay_box1')),
                      const SizedBox(height: 10),
                      _CheckRow(text: t('pay_box2')),
                      const SizedBox(height: 10),
                      _CheckRow(text: t('pay_box3')),
                      const SizedBox(height: 10),
                      _CheckRow(text: t('pay_box4')),

                      const SizedBox(height: 40),

                      // ===== BUY BUTTON (pay_btn) =====
                      GestureDetector(
                        onTap: _loadingPurchase ? null : _buyAdvisor,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF04D718),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [],
                          ),
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            t('buy_btn'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Color.fromARGB(255, 255, 255, 255),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ===== SUBTEXT under button (pay_btn_sub) =====
                      Text(
                        t('buy_btn_sub'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ===== RESTORE =====
                      GestureDetector(
                        onTap: _loadingPurchase ? null : _restorePurchases,
                        child: const Text(
                          'Restore purchase',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // ===== BIG "Advisor" =====
                      const Text(
                        'Advisor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w900,
                          fontSize: 42,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== BOTTOM TEXT =====
                      Text(
                        t('pay_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w700,
                          fontSize: 36,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 90),
                      _OfflineAdvisorCard(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // LOADING OVERLAY
              if (_loadingPurchase)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    alignment: AlignmentDirectional.center,
                    child: const CupertinoActivityIndicator(radius: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// Check row widget
// =========================
class _CheckRow extends StatelessWidget {
  final String text;

  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 2),
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFF04D718),
            shape: BoxShape.circle,
          ),
          alignment: AlignmentDirectional.center,
          child: const Icon(
            Icons.check,
            size: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF04D718),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineAdvisorCard extends StatelessWidget {
  const _OfflineAdvisorCard();

  String t(String key) => TranslationsStore.get(key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F4),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t('offline_text1'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.black,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PremiumRoute.push(
                  const AudioGetPage(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    Color(0xFF6BE11B),
                    Color(0xFF3FD500),
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              alignment: AlignmentDirectional.center,
              child: Text(
                'Offline Advisor',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w900,
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
}
