import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/editable_profile_screen.dart';
import 'screens/task_manager_screen.dart';
import 'screens/habit_tracker_screen.dart'; // <-- Import Habit Tracker

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/tasks': (context){
          final user = FirebaseAuth.instance.currentUser;
          return TaskManagerScreen(userId: user?.uid ?? '');
        },
        '/habits': (context) => const HabitTrackerScreen(),
        '/profile': (context) => EditableProfileScreen(
              onProfileUpdated: () {
                // Note: This will only work from within a valid Scaffold context
                // So if you need to show a snackbar, it should be moved to the profile screen
              },
            ),
      },
    );
  }
}
