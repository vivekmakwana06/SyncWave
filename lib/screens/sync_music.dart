import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sync_music/screens/sync_music_player.dart';
import 'package:sync_music/theme/colors.dart';

class SyncMusicCollection extends StatefulWidget {
  const SyncMusicCollection({Key? key}) : super(key: key);

  @override
  State<SyncMusicCollection> createState() => _SyncMusicCollectionState();
}

class _SyncMusicCollectionState extends State<SyncMusicCollection> {
  TextEditingController syncController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      appBar: AppBar(
        backgroundColor: Color(0xFF221e3b),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Color(0xff6157ff),
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // SizedBox(
            //   width: 10,
            //   height: 5,
            // ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                gradient: LinearGradient(
                  begin: Alignment(-0.95, 0.0),
                  end: Alignment(1.0, 0.0),
                  colors: [Color(0xff6157ff), Color(0xffee49fd)],
                ),
              ),
              child: Icon(
                Icons.sync,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Music',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
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
              height: 60,
            ),
            Text(
              'Enter Sync code to sync music on your device..',
              style: TextStyle(
                fontWeight: FontWeight.w200,
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment(-0.95, 0.0),
                  end: Alignment(1.0, 0.0),
                  colors: [Color(0xff6157ff), Color(0xffee49fd)],
                ),
              ),
              padding: EdgeInsets.all(30),
              child: Icon(
                Icons.music_note,
                color: Colors.white,
                size: 100, // Choose your desired size
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                maxLength: 6,
                enableIMEPersonalizedLearning: false,
                keyboardType: TextInputType.number,
                controller: syncController,
                decoration: const InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xffee49fd), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xffee49fd), width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xffee49fd), width: 3),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  labelText: 'Sync Code',
                  labelStyle: TextStyle(color: white),
                ),
                textInputAction: TextInputAction.done,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                gradient: LinearGradient(
                  begin: Alignment(-0.95, 0.0),
                  end: Alignment(1.0, 0.0),
                  colors: [Color(0xff6157ff), Color(0xffee49fd)],
                ),
              ),
              margin: EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 20,
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
