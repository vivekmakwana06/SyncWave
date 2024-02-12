import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sync_music/SyncPlayerLibrary/SongLibrary.dart';
import 'package:sync_music/SyncPlayerLibrary/SongLibraryPlayingpage.dart';
import 'package:sync_music/screens/InbuildPlaylist.dart';
import 'package:sync_music/screens/sync_music.dart';

class homePage extends StatefulWidget {
  final String? userEmail;
  final TextEditingController emailController;
  final num? partyId;
  final String? random;
  final Timestamp? PartyDateTime;
  final int? playerId;

  const homePage({
    Key? key,
    required this.userEmail,
    required this.emailController, // Receive the controller
    this.partyId,
    this.random,
    this.PartyDateTime,
    this.playerId,
  }) : super(key: key);

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  bool isHostCreated = false;

  @override
  Widget build(BuildContext context) {
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
                await createHost();
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
                int playerId = 1; // You need to define the playerId here

                if (playerId == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SyncMusicCollection(),
                    ),
                  ).then((value) {
                    if (value != null && value) {
                      setState(() {
                        isHostCreated = true;
                      });
                    }
                  });
                } else if (playerId == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SyncMusicInBuildPlaylist(),
                    ),
                  );
                } else {
                  // Handle the case when playerId is neither 1 nor 2
                  print("Invalid playerId");
                }
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
            if (isHostCreated)
              Text(
                'Successfully Joined',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 18,
                ),
              ),
            SizedBox(
              height: 30,
            ),
            Divider(
              thickness: .5,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'Connected Devices...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createHost() async {
    if (widget.userEmail != null) {
      QuerySnapshot<Map<String, dynamic>> latestPartySnapshot =
          await FirebaseFirestore.instance
              .collection('party')
              .orderBy('party_id', descending: true)
              .limit(1)
              .get();

      int newPartyId = (latestPartySnapshot.docs.isEmpty)
          ? 1
          : int.parse(latestPartySnapshot.docs.first['party_id']) + 1;

      var random = Random();
      int generatedCode = 100000 + random.nextInt(999999 - 100000);

      await FirebaseFirestore.instance
          .collection("party")
          .doc(generatedCode.toString())
          .set({
        'party_id': newPartyId.toString(),
        'host_id': widget.userEmail.toString(),
        'party_code': generatedCode.toString(),
        'party_dateTime': DateTime.now(),
      }).then((value) {
        openDialog(generatedCode.toString());
      }).catchError((error) {
        print("Failed to create host: $error");
      });
    } else {
      print("User email is null");
    }
  }

  Future<void> openDialog(String generatedCode) => showDialog(
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
                      generatedCode,
                      style: TextStyle(color: Colors.green, fontSize: 50),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InbuildPlaylist(
                            userEmail: widget.userEmail,
                            generatedCode: generatedCode.toString(),
                            isHostCreated: true,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "Let's Create...",
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
