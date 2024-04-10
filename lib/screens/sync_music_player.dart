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
        bool exited =
            (snapshot.data() as Map<String, dynamic>?)?['party_status'] ??
                false;

        if (isPlaying) {
          // Music is playing, display music detail screen
          setState(() {
            data = snapshot.data() as Map<String, dynamic>;
            showSyncingScreen = false;
          });
        } else if (!exited) {
          // Music is not playing yet, continue showing syncing screen
          setState(() {
            showSyncingScreen = true;
          });
        } else {
          // Host has exited
          setState(() {
            hostExited = true;
          });

          // Refresh UI to display host exited screen
          setState(() {});
        }

        // Update UI with new 'currentPosition' value
        setState(() {
          // Update the 'data' map with the new 'currentPosition'
          data?['currentPosition'] =
              (snapshot.data() as Map<String, dynamic>?)?['currentPosition'] ??
                  0;
        });
      } else {
        // Document does not exist, handle it based on your app logic
        setState(() {
          showSyncingScreen = true;
        });
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          gradient: LinearGradient(
            begin: Alignment(-0.95, 0.0),
            end: Alignment(1.0, 0.0),
            colors: [Color(0xff6157ff), Color(0xffee49fd)],
          ),
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
          backgroundColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Text(
              'Leave Host',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 245, 245, 245),
                fontSize: 16.5,
              ),
            ),
          ),
        ),
      ),
      body: showSyncingScreen
          ? buildSyncingScreen()
          : hostExited
              ? buildHostExitedScreen()
              : buildMusicDetailScreen(),
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
                textStyle: TextStyle(color: Colors.white, fontSize: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHostExitedScreen() {
    return Container(
      color: Color(0xFF221e3b),
      child: Center(
        child: Text(
          "This host has already exited.",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget buildMusicDetailScreen() {
    if (data == null) {
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
      color: Color(0xff6157ff),
      img: imgUrl,
      songUrl: songUrl,
      currentPosition: currentPosition,
      onSongUrlChanged: (newSongUrl) {
        setState(() {
          songUrl = newSongUrl;
        });
        sync.doc(widget.docId).update({'songUrl': newSongUrl});
      },
    );
  }
}
