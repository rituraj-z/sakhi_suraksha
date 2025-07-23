import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'home_navigation.dart';

List<CameraDescription> cameras =
    []; 

const SUPABASE_URL = 'https://ejaszjmffqsniquhzvfb.supabase.co';
const SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqYXN6am1mZnFzbmlxdWh6dmZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1NzA5NTgsImV4cCI6MjA2ODE0Njk1OH0.HX3ije8OMs435GTUSDOM0HV2_eNc_yIONdcZXv-J4lo';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sakhi Suraksha',
      theme: ThemeData(
        brightness: Brightness.dark, 
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor:
              Colors.transparent,
          elevation: 0, 
        ),
        cardColor: Colors.grey[900], 
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[800],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
      home: const AuthWrapper(), 
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // User signed in, navigate to InitialSetupWrapper to check user name/number
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const InitialSetupWrapper()),
        );
      } else if (event == AuthChangeEvent.signedOut) {
        // User signed out, navigate to AuthScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Supabase.instance.client.auth.currentUser == null
            ? const AuthScreen()
            : const InitialSetupWrapper(),
      ),
    );
  }
}
