import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sync_music/screens/sync_music_player.dart';
import 'package:sync_music/theme/colors.dart';

class SyncCode extends StatefulWidget {
  const SyncCode({Key? key}) : super(key: key);

  @override
  State<SyncCode> createState() => _SyncCodeState();
}

class _SyncCodeState extends State<SyncCode> {
  TextEditingController syncController = TextEditingController();
  bool showErrorMessage = false;
  bool showEmptyFieldError = false;

  late String _userName;
  late String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _userName = '';
    _loadUserName();
  }

  Future<String?> getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.email;
    }
    return null;
  }

  void _loadUserName() async {
    String? userEmail = await getUserName();
    if (userEmail != null) {
      setState(() {
        // Set the userEmail to a variable to use in the welcome message
        _userName = userEmail;
      });
    }
  }

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
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
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

  Future<void> storeSyncUserData(String hostCode) async {
    try {
      // Get the current date and time
      DateTime now = DateTime.now();
      Timestamp timestamp = Timestamp.fromDate(now);

      // Store sync user data in Firestore
      await FirebaseFirestore.instance.collection('SyncUser').add({
        'host_code': hostCode,
        'email': _userName,
        'datetime': timestamp,
      });
    } catch (e) {
      print('Error storing sync user data: $e');
    }
  }

  Future<void> storeSyncUserData1(String hostCode) async {
    try {
      // Get the current date and time
      DateTime now = DateTime.now();
      Timestamp timestamp = Timestamp.fromDate(now);

      // Store sync user data in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection('SyncUser')
          .add({
        'host_code': hostCode,
        'email': _userName,
        'datetime': timestamp,
      });
    } catch (e) {
      print('Error storing sync user data: $e');
    }
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
              height: 50,
            ),
            Container(
              height: 250,
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
                size: 150, // Choose your desired size
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 30),
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
                  labelText: 'Enter Sync Code',
                  labelStyle: TextStyle(color: white, fontSize: 27),
                ),
                textInputAction: TextInputAction.done,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            if (showEmptyFieldError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Sync code cannot be empty',
                  style: TextStyle(color: Colors.red, fontSize: 25),
                ),
              ),
            if (showErrorMessage)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Wrong host code',
                  style: TextStyle(color: Colors.red, fontSize: 25),
                ),
              ),
            Container(
              height: 50,
              width: 120,
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
                  String hostCode = syncController.text;
                  if (hostCode.isEmpty) {
                    setState(() {
                      showEmptyFieldError = true;
                      showErrorMessage = false;
                    });
                  } else {
                    // Check if the host code is correct
                    bool isValidCode = await checkHostCodeValidity(hostCode);
                    if (isValidCode) {
                      setState(() {
                        showEmptyFieldError = false;
                        showErrorMessage = false;
                      });
                      // Store sync user data
                      await storeSyncUserData(hostCode);
                      await storeSyncUserData1(hostCode);
                      // Navigate to SyncMusicPlayer screen
                      Navigator.push(
                        context,
                        PageTransition(
                          alignment: Alignment.bottomCenter,
                          child: SyncMusicPlayer(docId: hostCode),
                          type: PageTransitionType.scale,
                        ),
                      );
                    } else {
                      setState(() {
                        showEmptyFieldError = false;
                        showErrorMessage = true;
                      });
                    }
                  }
                },
                child: const Text(
                  "Sync",
                  style: TextStyle(color: Colors.white, fontSize: 27),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> checkHostCodeValidity(String hostCode) async {
    // Query Firestore to check if the host code exists
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('party')
        .where('party_code', isEqualTo: hostCode)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
