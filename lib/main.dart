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
  if (!kIsWeb) {
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).init(widget.initialTheme);
    });
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
      debugShowCheckedModeBanner: false,

      themeMode: themeMode,
      theme: _light,
      darkTheme: _dark,

      home: const AuthGate(userMode: "student"),
    );
  }
}
