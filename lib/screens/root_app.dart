import 'package:flutter/material.dart';
import 'package:sync_music/screens/MusicPage.dart';
import 'package:sync_music/screens/homepage.dart';
import 'package:sync_music/screens/MyLibraryPage.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../theme/colors.dart';

class RootApp extends StatefulWidget {
  final String userEmail;

  const RootApp({Key? key, required this.userEmail}) : super(key: key);

  @override
  _RootAppState createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  int activeTab = 0;

  late TextEditingController emailController; // Initialize here

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(); // Initialize the controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      bottomNavigationBar: getFooter(),
      body: getBody(),
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: activeTab,
      children: [
        homePage(userEmail: widget.userEmail, emailController: emailController),
        Collection(),
        Profile()
      ],
    );
  }

  Widget getFooter() {
    return SalomonBottomBar(
      currentIndex: activeTab,
      onTap: (index) {
        print("Tapped on index: $index");
        setState(() {
          activeTab = index;
        });
      },
      items: [
        SalomonBottomBarItem(
          icon: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              gradient: activeTab == 0
                  ? LinearGradient(
                      begin: Alignment(-0.95, 0.0),
                      end: Alignment(1.0, 0.0),
                      colors: [Color(0xff6157ff), Color(0xffee49fd)],
                    )
                  : null,
              borderRadius:
                  BorderRadius.circular(30.0), // Adjust border radius as needed
            ),
            child: Icon(
              Icons.home,
              color: Colors.white,
            ),
          ),
          title: Text(
            "Home",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          selectedColor: primary,
        ),
        SalomonBottomBarItem(
          icon: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              gradient: activeTab == 1
                  ? LinearGradient(
                      begin: Alignment(-0.95, 0.0),
                      end: Alignment(1.0, 0.0),
                      colors: [Color(0xff6157ff), Color(0xffee49fd)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Icon(
              Icons.music_note,
              size: 27,
              color: Colors.white,
            ),
          ),
          title: Text(
            "Music",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          selectedColor: primary,
        ),
        SalomonBottomBarItem(
          icon: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              gradient: activeTab == 2
                  ? LinearGradient(
                      begin: Alignment(-0.95, 0.0),
                      end: Alignment(1.0, 0.0),
                      colors: [Color(0xff6157ff), Color(0xffee49fd)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          title: Text(
            "Profile",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          selectedColor: primary,
        ),
      ],
    );
  }
}
