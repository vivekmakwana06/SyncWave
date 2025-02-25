import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sync_music/screens/LoginRegisterPage.dart';
import 'package:sync_music/screens/music_detail_page.dart';
import 'package:sync_music/screens/root_app.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  await Firebase.initializeApp();
  initPathProvider();

  User? user = await AuthService.getCurrentUser();
  String? userId = user?.uid;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => FavoriteSongsProvider(userId ?? "")),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: SplashScreen(userId: userId),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

void initPathProvider() async {
  await getApplicationDocumentsDirectory();
}

class MyApp extends StatelessWidget {
  final String userEmail;
  final String? userId;

  const MyApp({Key? key, required this.userEmail, this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteSongsProvider(userEmail)),
      ],
      child: MaterialApp(
        title: 'Music App',
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
              return RootApp(userEmail: user.email!);
            } else {
              return AuthGate();
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthService {
  static Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }
}

class SplashScreen extends StatefulWidget {
  final String? userId; // Declare userId as a parameter

  const SplashScreen({Key? key, this.userId}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MyApp(userEmail: user.email!)),
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
      backgroundColor: Color(0xFF221e3b),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 400,
              width: 400,
              child: Image.asset('assets/sync.png'),
            ),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff6157ff), Color(0xffee49fd)],
                ).createShader(bounds);
              },
              child: ColorizeAnimatedTextKit(
                onTap: () {
                  print("Tap Event");
                },
                colors: [
                  Colors.purple,
                  Colors.blue,
                  Colors.yellow,
                  Colors.red,
                ],
                text: ["SyncWave"],
                textStyle: GoogleFonts.ubuntu(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ).copyWith(fontSize: 30),
                speed: const Duration(milliseconds: 100),
                totalRepeatCount: 5,
                pause: const Duration(milliseconds: 1),
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
