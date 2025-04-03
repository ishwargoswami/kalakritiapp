import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kalakritiapp/screens/auth/login_screen.dart';
import 'package:kalakritiapp/screens/home_screen.dart';
import 'package:kalakritiapp/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  // Split the Sanskrit text into individual characters for animation
  final List<String> _sanskritChars = ['क', 'ला', 'कृ', 'ति'];
  final List<String> _taglineWords = ['Vocal', 'for', 'Local'];
  
  // Animation timing variables
  final int _charAnimationDuration = 400; // milliseconds per character
  final int _charAnimationDelay = 200; // milliseconds between characters
  final int _taglineDelay = 1200; // milliseconds before tagline starts
  
  @override
  void initState() {
    super.initState();
    // Navigate after animations complete
    Future.delayed(Duration(milliseconds: 
      _charAnimationDelay * _sanskritChars.length + 
      _taglineDelay + 
      _charAnimationDelay * _taglineWords.length + 
      1000
    ), () {
      _checkAuthState();
    });
  }

  // Check if user is logged in and onboarding is completed
  Future<void> _checkAuthState() async {
    try {
      print('Checking authentication state...');
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      print('Onboarding completed: $onboardingCompleted');
      
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final bool isLoggedIn = currentUser != null;
      print('Is logged in: $isLoggedIn, User: ${currentUser?.uid}');
      
      if (mounted) {
        if (!onboardingCompleted) {
          print('Navigating to OnboardingScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else if (!isLoggedIn) {
          print('Navigating to LoginScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else {
          print('Navigating to HomeScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      print('Error in auth state check: $e');
      // Default to onboarding if there's an error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sanskrit Text animation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _sanskritChars.length,
                (index) {
                  return FadeInDown(
                    duration: Duration(milliseconds: _charAnimationDuration),
                    delay: Duration(milliseconds: index * _charAnimationDelay),
                    from: 30,
                    child: ZoomIn(
                      duration: Duration(milliseconds: _charAnimationDuration),
                      delay: Duration(milliseconds: index * _charAnimationDelay),
                      child: Text(
                        _sanskritChars[index],
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tagline animation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _taglineWords.length,
                (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FadeInUp(
                      duration: Duration(milliseconds: _charAnimationDuration),
                      delay: Duration(milliseconds: _taglineDelay + index * _charAnimationDelay),
                      from: 20,
                      child: Text(
                        _taglineWords[index],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: theme.colorScheme.secondary,
                          letterSpacing: 1.2,
                          fontWeight: index == 0 || index == 2 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Animated underline
            FadeIn(
              delay: Duration(milliseconds: _taglineDelay + _taglineWords.length * _charAnimationDelay),
              duration: const Duration(milliseconds: 500),
              child: SlideInLeft(
                delay: Duration(milliseconds: _taglineDelay + _taglineWords.length * _charAnimationDelay),
                duration: const Duration(milliseconds: 800),
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 2,
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 