import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:igit_connects/screens/post/full_post_screen.dart';
import 'package:igit_connects/screens/premium/payment_result_screen.dart';
import 'package:igit_connects/core/auth_gate.dart';
import 'package:igit_connects/core/theme_provider.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:igit_connects/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:igit_connects/features/broadcast/models/broadcast_model.dart';
import 'package:igit_connects/features/broadcast/screens/broadcast_details_screen.dart';
import 'package:igit_connects/screens/notifications/notification_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init .env & Theme
  ThemeMode? initialTheme;
  await Future.wait([
    dotenv.load(fileName: ".env").then((_) => debugPrint(".env Loaded")),
    ThemeNotifier.loadInitial().then((theme) => initialTheme = theme),
  ]);

  // Init Supabase & Firebase
  await Future.wait([
    Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ).then((_) => debugPrint("Supabase Initialized")),

    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((e) {
      if (e is FirebaseException && e.code == 'duplicate-app') {
        return Firebase.app();
      }
      throw e;
    }).then((_) => debugPrint("Firebase Initialized")),
  ]);

  // Background inits (AdMob, Notifications)
  Future.microtask(() async {
    if (!kIsWeb) {
      try {
        await NotificationService().initialize();
        debugPrint("NotificationService Initialized");
      } catch (e) {
        debugPrint("Error initializing NotificationService: $e");
      }
    }

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        await MobileAds.instance.initialize();
        debugPrint("AdMob Initialized");
      } catch (e) {
        debugPrint("Error initializing AdMob: $e");
      }
    }
  });

  runApp(ProviderScope(child: MyApp(initialTheme: initialTheme ?? ThemeMode.system)));
}

final navigatorKey = GlobalKey<NavigatorState>();

// Global deep link/notification state
typedef DeepLinkAction = void Function();
DeepLinkAction? pendingDeepLinkAction;
bool isMainScreenReady = false;

class MyApp extends ConsumerStatefulWidget {
  final ThemeMode initialTheme;
  const MyApp({super.key, required this.initialTheme});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).init(widget.initialTheme);
    });
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Cold start link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial link: $e");
    }

    // Background running link
    _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(uri);
    });
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    String? postId;

    // Handle custom scheme: linkpeer://post/123
    if (uri.scheme == 'linkpeer' &&
        uri.host == 'post' &&
        uri.pathSegments.isNotEmpty) {
      postId = uri.pathSegments.first;
    }
    // Handle universal link: https://linkpeer.swynx.dev/post/123
    else if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host == 'linkpeer.swynx.dev' &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'post') {
      postId = uri.pathSegments[1];
    }


    if (postId != null) {
      try {
        final post = await Supabase.instance.client
            .from('posts')
            .select()
            .eq('id', postId)
            .single();

        final action = () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => FullPostScreen(post: post)),
          );
        };
        if (isMainScreenReady) {
          action();
        } else {
          pendingDeepLinkAction = action;
        }
      } catch (e) {
        debugPrint('Error loading deep linked post: $e');
      }
      return;
    }

    // Handle Broadcast Link: linkpeer://broadcast/123
    if (uri.scheme == 'linkpeer' &&
        uri.host == 'broadcast' &&
        uri.pathSegments.isNotEmpty) {
      final broadcastId = uri.pathSegments.first;
      try {
        final broadcastData = await Supabase.instance.client
            .from('broadcasts')
            .select()
            .eq('id', broadcastId)
            .single();

        final action = () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => BroadcastDetailsScreen(
                broadcast: BroadcastModel.fromJson(broadcastData),
              ),
            ),
          );
        };
        if (isMainScreenReady) {
          action();
        } else {
          pendingDeepLinkAction = action;
        }
      } catch (e) {
        debugPrint('Error loading deep linked broadcast: $e');
        // Broadcast was deleted or not found
        final action = () {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(initialIndex: 1),
              ),
            );
            Future.delayed(const Duration(milliseconds: 300), () {
              if (navigatorKey.currentContext != null) {
                ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "This broadcast has been deleted or is no longer available.",
                    ),
                  ),
                );
              }
            });
          }
        };
        if (isMainScreenReady) {
          action();
        } else {
          pendingDeepLinkAction = action;
        }
      }
      return;
    }

    // Handle Payment Results: linkpeer://payment/success?txnId=...
    if (uri.scheme == 'linkpeer' &&
        uri.host == 'payment' &&
        uri.pathSegments.isNotEmpty) {
      final status = uri.pathSegments.first;
      final txnId = uri.queryParameters['txnId'];
      final action = () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => PaymentResultScreen(status: status, txnId: txnId),
          ),
        );
      };
      if (isMainScreenReady) {
        action();
      } else {
        pendingDeepLinkAction = action;
      }
    }
  }

  static TextTheme _poppins(TextTheme base) =>
      GoogleFonts.poppinsTextTheme(base).apply(decoration: TextDecoration.none);

  static ThemeData get _dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      textTheme: _poppins(base.textTheme),
      scaffoldBackgroundColor: const Color(0xff141413),
      colorScheme: base.colorScheme.copyWith(
        surface: const Color(0xff141413),
        surfaceContainer: const Color(0xff1E1E1C),
      ),
      extensions: [AppColors.darkTheme],
    );
  }

  static ThemeData get _light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      textTheme: _poppins(base.textTheme),
      scaffoldBackgroundColor: const Color(0xffF5F5F3),
      colorScheme: base.colorScheme.copyWith(
        surface: const Color(0xffF5F5F3),
        surfaceContainer: const Color(0xffFFFFFF),
      ),
      extensions: [AppColors.lightTheme],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

      themeMode: themeMode,
      theme: _light,
      darkTheme: _dark,

      home: const AuthGate(userMode: "student"),
    );
  }
}
