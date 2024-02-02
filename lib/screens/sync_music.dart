import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sync_music/screens/sync_music_player.dart';
import 'package:sync_music/theme/colors.dart';
// import 'package:youtube_sync_music/screens/sync_music_player.dart';
// import 'package:youtube_sync_music/theme/colors.dart';

class SyncMusic extends StatefulWidget {
  const SyncMusic({Key? key}) : super(key: key);

  @override
  State<SyncMusic> createState() => _SyncMusicState();
}

class _SyncMusicState extends State<SyncMusic> {
  TextEditingController syncController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1b1f),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1b1f),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 236, 146, 3),
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            // SizedBox(
            //   width: 10,
            //   height: 5,
            // ),
            Icon(
              Icons.sync,
              color: Color.fromARGB(255, 236, 146, 3),
              size: 30,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Sync Music',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Enter Sync code to sync music on your device',
                  style: TextStyle(
                    fontWeight: FontWeight.w200,
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      body: buildSyncLogin(),
    );
  }

  Widget buildSyncLogin() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 100,
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Color.fromARGB(255, 236, 146, 3), width: 9),
              ),
              padding: EdgeInsets.all(30),
              child: Icon(
                Icons.music_note,
                color: Colors.white,
                size: 100, // Choose your desired size
              ),
            ),
            SizedBox(
              height: 80,
            ),
            // Image.asset(
            //   "assets/images/logo.png",
            // ),
            TextField(
              style: const TextStyle(color: Colors.white),
              maxLength: 6,
              enableIMEPersonalizedLearning: false,
              keyboardType: TextInputType.number,
              controller: syncController,
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primary, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primary, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: primary, width: 3),
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                labelText: 'Sync Code',
                labelStyle: TextStyle(color: white),
              ),
              textInputAction: TextInputAction.done,
            ),
            Container(
              margin: EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(255, 236, 146, 3),
                  onPrimary: Colors.white,
                ),
                onPressed: () async {
                  String syncCode = syncController.text ?? "";
                  if (syncCode.isNotEmpty) {
                    Navigator.push(
                      context,
                      PageTransition(
                        alignment: Alignment.bottomCenter,
                        child: SyncMusicPlayer(docId: syncCode),
                        type: PageTransitionType.scale,
                      ),
                    );
                  } else {
                    // Handle the case where the sync code is empty
                    // Show an error message or take appropriate action
                    print("Sync code is empty");
                  }
                },
                child: const Text(
                  "Sync",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
