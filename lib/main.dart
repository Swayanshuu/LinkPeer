import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:igit_connects/Controllers/AuthGate.dart';
import 'package:igit_connects/Controllers/ThemeProvider.dart';
import 'package:igit_connects/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:igit_connects/Screens/Post/FullPostScreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always call initializeApp() and catch the 'duplicate-app' error that
  // Flutter Web raises when the Firebase JS SDK is already initialized
  // (e.g. after a hot-restart). Any other error is rethrown.
  // Using Firebase.apps.isEmpty is NOT safe on web — accessing that getter
  // via JS interop before the SDK is ready throws 'Unexpected null value'.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  debugPrint("Firebase Initialized");

  await dotenv.load(fileName: ".env");
  debugPrint(".env Loaded");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  debugPrint("Supabase Initialized");
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    await MobileAds.instance.initialize();
  }
  debugPrint("AdMob Initialized");
  final initialTheme = await ThemeNotifier.loadInitial();

  runApp(ProviderScope(child: MyApp(initialTheme: initialTheme)));
}

class MyApp extends ConsumerStatefulWidget {
  final ThemeMode initialTheme;
  const MyApp({super.key, required this.initialTheme});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
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
    // 1. Handle deep link if app was closed (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial link: $e");
    }

    // 2. Handle deep link if app is already running in background
    _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(uri);
    });
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    String? postId;

    // Handle custom scheme: linkpeer://post/123
    if (uri.scheme == 'linkpeer' && uri.host == 'post' && uri.pathSegments.isNotEmpty) {
      postId = uri.pathSegments.first;
    } 
    // Handle verified App Link: https://go.swynx.dev/xyz
    else if (uri.host == 'go.swynx.dev' && uri.pathSegments.isNotEmpty) {
      final slug = uri.pathSegments.first;
      // Skip API routes
      if (slug != 'api') {
        try {
          final response = await http.get(Uri.parse('https://go.swynx.dev/api/links/$slug'));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final targetUrl = data['targetUrl'] as String?;
            if (targetUrl != null && targetUrl.startsWith('linkpeer://post/')) {
              postId = targetUrl.split('/').last;
            }
          }
        } catch (e) {
          debugPrint('Failed to resolve shortlink: $e');
        }
      }
    }

    if (postId != null) {
      try {
        final post = await Supabase.instance.client
            .from('posts')
            .select()
            .eq('id', postId)
            .single();
            
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => FullPostScreen(post: post),
          ),
        );
      } catch (e) {
        debugPrint('Error loading deep linked post: $e');
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,

      themeMode: themeMode,
      theme: _light,
      darkTheme: _dark,

      home: const AuthGate(userMode: "student"),
    );
  }
}
