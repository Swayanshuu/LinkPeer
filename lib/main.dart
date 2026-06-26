import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:igit_connects/Controllers/AuthGate.dart';
import 'package:igit_connects/Controllers/ThemeProvider.dart';
import 'package:igit_connects/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Firebase Initialized");

  await dotenv.load(fileName: ".env");
  debugPrint(".env Loaded");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  debugPrint("Supabase Initialized");

  // ── Read stored theme preference BEFORE runApp so there is no flash ────────
  // • First launch → ThemeMode.system  (follows device dark/light setting)
  // • Subsequent launches → user's last manually chosen theme (dark or light)
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
