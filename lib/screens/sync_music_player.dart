import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sync_music/screens/sync_music_detail_page.dart';
import 'package:sync_music/theme/colors.dart';
// import 'package:youtube_sync_music/screens/sync_music_detail_page.dart';
// import 'package:youtube_sync_music/theme/colors.dart';

class SyncMusicPlayer extends StatefulWidget {
  final String docId;
  const SyncMusicPlayer({Key? key, required this.docId}) : super(key: key);

  @override
  State<SyncMusicPlayer> createState() => _SyncMusicPlayerState();
}

class _SyncMusicPlayerState extends State<SyncMusicPlayer> {
  CollectionReference sync = FirebaseFirestore.instance.collection('sync');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: sync.doc(widget.docId.toString()).get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {        
            return const Text("Something went wrong");
          }

          if (snapshot.hasData && !snapshot.data!.exists) {
            return const Text("Document does not exist");
          }

          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic>? data =
                snapshot.data?.data() as Map<String, dynamic>?;

            // Extracting data with null-aware operators to handle potential null values
            Duration currentPosition =
                Duration(milliseconds: data?['currentPosition'] ?? 0);
            String title = data?['musicName'] ?? 'Unknown Title';
            String description = data?['artistName'] ?? 'Unknown Artist';
            String imgUrl = data?['imgUrl'] ?? '';
            String songUrl = data?['songUrl'] ?? '';

            return SyncMusicDetailPage(
              currentPosition: currentPosition,
              title: title,
              description: description,
              color: Colors.red,
              img: imgUrl,
              songUrl: songUrl,
            );
          }

          return const Scaffold(
            backgroundColor: const Color(0xFF0c091c),
            body: Center(child: CircularProgressIndicator(color: primary)),
          );
        },
      ),
    );
  }
}

