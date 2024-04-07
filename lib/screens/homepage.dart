import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sync_music/screens/MusicPage.dart';
import 'package:sync_music/screens/music_detail_page.dart';
import 'package:sync_music/screens/sync_music.dart';

class homePage extends StatefulWidget {
  final String? userEmail;
  final TextEditingController emailController;
  final num? partyId;
  final String? random;
  final Timestamp? PartyDateTime;
  final bool? partyStatus;
  final int? playerId;
  final String? musicName;
  final String? songUrl;
  final String? imgUrl;
  final String? artistName;
  final String? party_status;

  const homePage({
    Key? key,
    this.musicName,
    this.party_status,
    this.imgUrl,
    this.partyStatus,
    this.artistName,
    this.songUrl,
    required this.userEmail,
    required this.emailController,
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
  int? result;
  bool party_status = false;
  int _selected = 1;
  bool syncMusic = false;

  Widget CreateHost() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text(
          Text(
            "Let's Create .... ",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              gradient: LinearGradient(
                begin: Alignment(-0.95, 0.0),
                end: Alignment(1.0, 0.0),
                colors: [Color(0xff6157ff), Color(0xffee49fd)],
              ),
            ),
            child: ElevatedButton(
              onPressed: () async {
                await createHost();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation:
                    20, // Adjust the elevation to increase the button's size
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              child: Text(
                'Create Host',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget JoinHost() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Let's Join .... ",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              gradient: LinearGradient(
                begin: Alignment(-0.95, 0.0),
                end: Alignment(1.0, 0.0),
                colors: [Color(0xff6157ff), Color(0xffee49fd)],
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SyncCode(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 20,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              child: Text(
                'Join Host',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      appBar: AppBar(
        backgroundColor: Color(0xFF221e3b),
        elevation: 0,
        title: Row(
          children: [
            SizedBox(
              width: 10,
              height: 5,
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
              child: Icon(
                Icons.sync,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SizedBox(
                //   height: 10,
                // ),
                Text(
                  'HomePage',
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 80,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = 1;
                      });
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.21,
                      width: MediaQuery.of(context).size.height * 0.21,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: _selected == 1
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xff6157ff), Color(0xffee49fd)],
                              )
                            : null,
                        color: _selected == 1 ? null : Color(0xff181818),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.person_add_solid,
                            color: Colors.white,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Create",
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.038,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = 2;
                      });
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.21,
                      width: MediaQuery.of(context).size.height * 0.21,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: _selected == 2
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xff6157ff), Color(0xffee49fd)],
                              )
                            : null,
                        color: _selected == 2 ? null : Color(0xff181818),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.dot_radiowaves_left_right,
                              color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            "Join",
                            style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.038,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.30,
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: Color(0xff181818),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: _selected == 1 ? CreateHost() : JoinHost(),
              ),
            ],
          ),
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
      int result = 100000 + random.nextInt(999999 - 100000);

      await FirebaseFirestore.instance
          .collection("party")
          .doc(result.toString())
          .set({
        'party_id': newPartyId.toString(),
        'host_id': widget.userEmail.toString(),
        'party_code': result.toString(),
        'party_dateTime': DateTime.now(),
        'party_status': true,
      }).then((value) {
        openDialog(result.toString());
      }).catchError((error) {
        print("Failed to create host: $error");
      });

    
    } else {
      print("User email is null");
    }
  }

  Future<void> openDialog(String result) => showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Host Code",
              style: TextStyle(color: Color(0xff6157ff), fontSize: 24),
            ),
            content: Container(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color(0xff6157ff),
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
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      gradient: LinearGradient(
                        begin: Alignment(-0.95, 0.0),
                        end: Alignment(1.0, 0.0),
                        colors: [Color(0xff6157ff), Color(0xffee49fd)],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Collection(
                              // userEmail: widget.userEmail,
                              result: result.toString(),
                              // party_status: true,
                              party_status: true,
                              isCreatingHost: true,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "Let's Create..",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 60,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
