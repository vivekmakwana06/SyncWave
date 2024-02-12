import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sync_music/AdminPanel/AdminPage.dart';
import 'package:sync_music/screens/LoginRegisterPage.dart';
import 'package:sync_music/screens/root_app.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initPathProvider(); 
  runApp(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}



void initPathProvider() async {
  await getApplicationDocumentsDirectory();
}

class MyApp extends StatelessWidget {
  final String userEmail;

  const MyApp({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: FutureBuilder<User?>(
        future: AuthService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          } else if (snapshot.hasError) {
            return AuthGate();
          } else if (snapshot.hasData && snapshot.data != null) {
            User user = snapshot.data!;
            if (AuthService.isAdminUser(user.email!, "dummy_password")) {
              return AdminDashboard();
            } else {
              return RootApp(userEmail: user.email!);
            }
          } else {
            return AuthGate();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthService {
  static bool isAdminUser(String email, String password) {
    // Your implementation here
    return email == 'vivekmakwana@gmail.com' && password == 'vivek_makwana_';
  }

  static Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    navigateToHome();
  }

  Future<void> navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));

    if (_controller.isAnimating) {
      _controller.stop();
    }

    if (mounted) {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        bool isAdmin = AuthService.isAdminUser(user.email!, "vivek_makwana_");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) {
            if (isAdmin) {
              return AdminDashboard();
            } else {
              return MyApp(userEmail: user.email!);
            }
          }),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthGate()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1b1f),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 400,
              width: 400,
              child: Image.asset('assets/logo1.png'),
            ),
            TypewriterAnimatedTextKit(
              onTap: () {
                print("Tap Event");
              },
              text: ["SyncWave"],
              textStyle: GoogleFonts.ubuntu(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ).copyWith(fontSize: 30),
              speed: const Duration(milliseconds: 100),
              totalRepeatCount: 1,
              displayFullTextOnTap: true,
              stopPauseOnTap: true,
            ),
          ],
        ),
      ),
    );
  }
}
