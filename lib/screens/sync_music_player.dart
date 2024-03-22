import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sync_music/screens/sync_music_detail_page.dart';

class SyncMusicPlayer extends StatefulWidget {
  final String docId;

  const SyncMusicPlayer({Key? key, required this.docId}) : super(key: key);

  @override
  State<SyncMusicPlayer> createState() => _SyncMusicPlayerState();
}

class _SyncMusicPlayerState extends State<SyncMusicPlayer> {
  CollectionReference sync = FirebaseFirestore.instance.collection('sync');

  late StreamSubscription<DocumentSnapshot> _subscription;

  bool showSyncingScreen = true;
  bool hostExited = false;

  Map<String, dynamic>? data;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Subscribe to document changes
    _subscription = sync.doc(widget.docId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        // Document exists
        bool isPlaying =
            (snapshot.data() as Map<String, dynamic>?)?['isPlaying'] ?? false;
        bool hostExited =
            (snapshot.data() as Map<String, dynamic>?)?['hostExited'] ?? false;

        if (isPlaying) {
          // Music is playing, display music detail screen
          setState(() {
            data = snapshot.data() as Map<String, dynamic>;
            showSyncingScreen = false;
          });
        } else if (hostExited) {
          // Host has exited, display host exited screen
          setState(() {
            showSyncingScreen = false;
          });
        } else {
          // Music is not playing yet, continue showing syncing screen
          setState(() {
            showSyncingScreen = true;
          });
        }
      } else {
        // Document does not exist, handle it based on your app logic
        setState(() {
          showSyncingScreen = true;
          hostExited = true; // Host has exited
        });
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      body: showSyncingScreen ? buildSyncingScreen() : buildMusicDetailScreen(),
    );
  }

  Widget buildHostExitedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Host Is Exit",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Navigate back
            },
            child: Text("Leave Host"),
          ),
        ],
      ),
    );
  }

  Widget buildSyncingScreen() {
    return Container(
      color: Color(0xFF221e3b),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/syncci.png',
              width: 400,
              height: 300,
            ),
            SizedBox(height: 16),
            TyperAnimatedTextKit(
              speed: Duration(milliseconds: 100),
              repeatForever: true,
              text: ['Syncing...'],
              textStyle: GoogleFonts.openSans(
                textStyle: TextStyle(color: Colors.white, fontSize: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMusicDetailScreen() {
    if (data == null) {
      // Handle the case when data is null (optional)
      return Container();
    }

    Duration currentPosition =
        Duration(milliseconds: data?['currentPosition'] ?? 0);
    String title = data?['musicName'] ?? 'Unknown Title';
    String description = data?['artistName'] ?? 'Unknown Artist';
    String imgUrl = data?['imgUrl'] ?? '';
    String songUrl = data?['songUrl'] ?? '';

    return SyncMusicDetailPage(
      title: title,
      description: description,
      color: Colors.red,
      img: imgUrl,
      songUrl: songUrl,
      currentPosition: currentPosition,
      onSongUrlChanged: (newSongUrl) {
        // Update the song URL in the parent widget's state
        setState(() {
          songUrl = newSongUrl;
        });
      },
    );
  }
}
