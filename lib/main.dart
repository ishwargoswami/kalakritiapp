import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kalakritiapp/firebase_options.dart';
import 'package:kalakritiapp/screens/splash_screen.dart';
import 'package:kalakritiapp/utils/theme.dart';

// Firebase configuration placeholder
// For Android: Add google-services.json to android/app/
// For iOS: Add GoogleService-Info.plist to ios/Runner/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue with the app even if Firebase fails to initialize
    // This will allow us to show a message to the user instead of crashing
  }
  
  runApp(const ProviderScope(child: KalakritiApp()));
}

class KalakritiApp extends ConsumerWidget {
  const KalakritiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kalakriti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: kalakritiColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
