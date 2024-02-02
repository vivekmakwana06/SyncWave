import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sync_music/screens/sync_music.dart';
import 'package:sync_music/theme/colors.dart';

class homePage extends StatefulWidget {
  final String? title;
  final String? description;
  final String? img;
  final String? songUrl;

  const homePage({
    Key? key,
    this.title,
    this.description,
    this.img,
    this.songUrl,
  }) : super(key: key);

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  String syncCode = "";
  int? result;
  bool syncMusic = false;

  @override
  Widget build(BuildContext context) {
    var random = Random();
    final docSync =
        FirebaseFirestore.instance.collection("sync").doc(result.toString());
    result ??= 100000 + random.nextInt(999999 - 100000);

    return Scaffold(
      backgroundColor: Color(0xFF1a1b1f),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1b1f),
        elevation: 0,
        title: const Row(
          children: [
            SizedBox(
              width: 10,
              height: 5,
            ),
            Icon(
              Icons.playlist_add,
              color: Color.fromARGB(255, 236, 146, 3),
              size: 34,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'HomePage',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Create Host And Join Party...',
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
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 60,
            ),
            ElevatedButton(
              onPressed: () async {
                syncMusic = true;
                docSync.set({
                  'musicName': widget.title ?? "",
                  'artistName': widget.description ?? "",
                  'songUrl': widget.songUrl ?? "",
                  'imgUrl': widget.img ?? ""
                });
                openDialog();
              },
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 236, 146, 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Create Host',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to SyncMusic page or your desired page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SyncMusic(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 236, 146, 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Join Host',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future openDialog() => showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Music Sync",
              style: TextStyle(
                  color: Color.fromARGB(255, 236, 146, 3), fontSize: 24),
            ),
            content: Container(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromARGB(255, 236, 146, 3),
                        width: 4.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                    child: Text(
                      result.toString(),
                      style: TextStyle(color: Colors.green, fontSize: 50),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color.fromARGB(255, 236, 146, 3),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
