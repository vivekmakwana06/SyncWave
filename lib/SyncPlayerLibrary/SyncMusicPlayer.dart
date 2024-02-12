import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sync_music/SyncPlayerLibrary/SyncMusicDetail.dart';
import 'package:sync_music/screens/sync_music_detail_page.dart';
import 'package:sync_music/theme/colors.dart';
// import 'package:youtube_sync_music/screens/sync_music_detail_page.dart';
// import 'package:youtube_sync_music/theme/colors.dart';

class SyncMusicPlayer1 extends StatefulWidget {
  final String? userEmail;
  final String? generatedCode;
  const SyncMusicPlayer1({Key? key, this.userEmail, this.generatedCode})
      : super(key: key);

  @override
  State<SyncMusicPlayer1> createState() => _SyncMusicPlayer1State();
}

class _SyncMusicPlayer1State extends State<SyncMusicPlayer1> {
  CollectionReference sync =
      FirebaseFirestore.instance.collection('SyncInbuildPlaylist');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: sync.doc(widget.generatedCode.toString()).get(),
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

            String musicName = data?['musicName'] ?? 'Unknown Title';
            String code =
                data?['code'] ?? ''; // Assuming 'code' is the image URL
            String downloadUrl = data?['downloadUrl'] ?? '';
            String documentId = data?['documentId'] ?? '';
            String userEmail = data?['userEmail'] ?? '';
            String generatedCode = data?['generatedCode'] ?? '';

            return SyncMusicPlayPage(
              // docId: widget.docId,
              musicName: musicName,
              code: code,
              downloadUrl: downloadUrl,
              documentId: documentId,
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
