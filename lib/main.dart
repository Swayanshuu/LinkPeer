import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:igit_connects/Controllers/AuthGate.dart';
import 'package:igit_connects/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Firebase Initialized");

  await dotenv.load(fileName: ".env");
  debugPrint(".env Loaded");

  await Supabase.initialize(url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,);
  debugPrint("Supabase Initialized");

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark(useMaterial3: true).textTheme,
        ).apply(decoration: TextDecoration.none),
      ),

      home: const AuthGate(
        userMode: "student",
      ),
    );
  }
}
