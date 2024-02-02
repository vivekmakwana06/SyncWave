import 'package:flutter/material.dart';
import 'package:sync_music/screens/PlaylistPage.dart';
import 'package:sync_music/screens/favorite.dart';
import 'package:sync_music/screens/MusicPage.dart';
import 'package:sync_music/screens/homepage.dart';
import 'package:sync_music/screens/sync_music.dart';
import 'package:sync_music/screens/upload_music_page.dart';
// import 'package:youtube_sync_music/screens/sync_music.dart';
// import 'package:youtube_sync_music/screens/upload_music_page.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      bottomNavigationBar: getFooter(),
      body: getBody(),
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: activeTab,
      children: [
        homePage(),
        // const SyncMusic(),
        const MusicPage(),
        // const Favorite(),

        // const Playlist(),

        Upload()
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
          icon: Icon(
            Icons.home,
            color: Colors.white,
          ),
          title: Text(
            "Home",
            style: TextStyle(color: Colors.white),
          ),
          selectedColor: primary,
        ),
        // SalomonBottomBarItem(
        //   icon: Icon(
        //     Icons.book,
        //     color: Colors.white,
        //   ),
        //   title: Text(
        //     "Sync Music",
        //     style: TextStyle(color: Colors.white),
        //   ),
        //   selectedColor: primary,
        // ),
        SalomonBottomBarItem(
          icon: Icon(
            Icons.music_note,
            size: 30, // Set the desired size here
            color: Colors.white,
          ),
          title: Text(
            "Music",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          selectedColor: primary,
        ),
        // SalomonBottomBarItem(
        //   icon: Icon(
        //     Icons.playlist_add,
        //     color: Colors.white,
        //   ),
        //   title: Text(
        //     "Playlist",
        //     style: TextStyle(color: Colors.white),
        //   ),
        //   selectedColor: primary,
        // ),
        SalomonBottomBarItem(
          icon: Icon(
            Icons.person,
            color: Colors.white,
          ),
          title: Text(
            "Profile",
            style: TextStyle(color: Colors.white),
          ),
          selectedColor: primary,
        ),
      ],
    );
  }
}
