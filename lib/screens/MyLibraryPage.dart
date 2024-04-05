import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:sync_music/screens/LoginRegisterPage.dart';
import 'package:sync_music/screens/favorite.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  TextEditingController songName = TextEditingController();
  TextEditingController artistName = TextEditingController();
  double uploadProgress = 0.0;

  late TabController _tabController;
  double imageUploadProgress = 0.0;
  late String imagepath, songPath;
  late Reference reference;
  late String _userName;
  var imageDownloadUrl, songDownloadUrl;
  PlatformFile? imageResult, songResult;

  File? _profileImage;
  bool _isUploading = false;
  bool _isImageUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  void selectImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        imageResult = result.files.first;
        File image = File(imageResult!.path!);
        imagepath = basename(image.path.toString());
        uploadImageFile(image.readAsBytesSync(), imagepath);
      });
    }
  }

  // Modified method to upload image file with progress tracking
  void uploadImageFile(Uint8List image, String imagepath) async {
    setState(() {
      _isImageUploading =
          true; // Set _isImageUploading to true when upload starts
      imageUploadProgress = 0.0; // Reset image upload progress
    });

    reference = FirebaseStorage.instance.ref().child(imagepath);
    UploadTask uploadTask = reference.putData(image);

    // Track image upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        imageUploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
      });
    });

    TaskSnapshot taskSnapshot = await uploadTask;
    imageDownloadUrl = await taskSnapshot.ref.getDownloadURL();

    // Reset _isImageUploading after completing the upload
    setState(() {
      _isImageUploading = false;
    });
  }

  uploadSongFile(Uint8List song, String songPath) async {
    setState(() {
      _isUploading = true; // Set _isUploading to true when upload starts
      uploadProgress = 0.0; // Reset upload progress when starting upload
    });

    reference = FirebaseStorage.instance.ref().child(songPath);
    UploadTask uploadTask = reference.putData(song);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
      });
    });

    TaskSnapshot taskSnapshot = await uploadTask;
    // Get the download URL
    songDownloadUrl = await taskSnapshot.ref.getDownloadURL();

    // Reset uploadProgress and _isUploading after completing the upload
    setState(() {
      uploadProgress = 0.0;
      _isUploading = false;
    });
  }

  void selectSong() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    setState(() {
      songResult = result!.files.first;
      File songFile = File(songResult!.path!);
      songPath = basename(songFile.path.toString());
      uploadSongFile(songFile.readAsBytesSync(), songPath);
    });
  }

  void finalUpload(
      BuildContext context, String userId, String userEmail) async {
    if (songResult != null) {
      try {
        File songFile = File(songResult!.path!);

        var data = {
          "user_email": userEmail, // Add the user's email to the data
          "song_name": basename(songFile.path),
          "artist_name": artistName.text,
          "song_url": songDownloadUrl.toString(),
          "image_url": imageDownloadUrl.toString(),
        };

        // Generate a unique document ID
        var docRef = await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("CustomCollection")
            .add(data);

        print("Document ID: ${docRef.id}");

        setState(() {
          songName.text = "";
          artistName.text = "";
          imageDownloadUrl = null;
          songDownloadUrl = null;
          songResult = null;
        });
      } catch (error) {
        print("Upload error: $error");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Upload Error"),
              content: Text(
                  "An error occurred during the upload. Please try again."),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Please select a song before uploading."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Icons.person,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Color(0xffee49fd),
          tabs: [
            Tab(text: 'Profile'),
            Tab(text: 'Custom Collection'),
          ],
        ),
      ),
      backgroundColor: Color(0xFF221e3b),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            child: Container(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(height: 30),
                      Text(
                        'Welcome to,',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          gradient: LinearGradient(
                            begin: Alignment(-0.95, 0.0),
                            end: Alignment(1.0, 0.0),
                            colors: [Color(0xff6157ff), Color(0xffee49fd)],
                          ),
                        ),
                        child: Text(
                          '$_userName',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      SizedBox(height: 80),
                      Divider(thickness: .4),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Favorite()),
                            );
                          },
                          child: Container(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 10,
                                ),
                                Icon(
                                  Icons.favorite,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  'Favorite Song',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(thickness: .4),
                      SizedBox(
                        height: 110,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Perform logout
                          await FirebaseAuth.instance.signOut();

                          // Navigate to the login page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => AuthGate()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          backgroundColor: Colors.red,
                          padding:
                              EdgeInsets.symmetric(vertical: 7, horizontal: 50),
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 5,
                    ),
                    // Divider(thickness: .1),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        gradient: LinearGradient(
                          begin: Alignment(-0.95, 0.0),
                          end: Alignment(1.0, 0.0),
                          colors: [Color(0xff6157ff), Color(0xffee49fd)],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () => selectImage(),
                        child: const Text(
                          "Select Image",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          // foregroundColor: Colors.white,
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isImageUploading) // Conditionally display the progress bar
                      LinearProgressIndicator(
                        value: imageUploadProgress,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xffee49fd),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageDownloadUrl != null
                              ? Image.network(imageDownloadUrl).image
                              : AssetImage("assets/placeholder_image.jpg"),
                          fit: BoxFit.cover,
                        ),
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(thickness: .4),
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
                        onPressed: () => selectSong(),
                        child: const Text(
                          "Select Song",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          // foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 20,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isUploading) // Conditionally display the progress bar
                      LinearProgressIndicator(
                        value: uploadProgress,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xffee49fd),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      " ${songResult?.name ?? ''}",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(thickness: .4),
                    const SizedBox(height: 10),
                    TextField(
                      controller: artistName,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Enter Artist Name",
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xffee49fd), width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xffee49fd), width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xffee49fd), width: 3),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(thickness: .4),
                    const SizedBox(height: 15),
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
                          String? userId =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (userId != null) {
                            finalUpload(context, userId, _userName);
                          } else {
                            // Handle the case where userId is null (e.g., user not authenticated)
                            print("User ID is null");
                          }
                        },
                        child: const Text(
                          "Upload",
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          // foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 60,
                          // backgroundColor: Color.fromARGB(255, 236, 146, 3),
                          padding:
                              EdgeInsets.symmetric(vertical: 7, horizontal: 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InkWell buildSettingsItem(IconData icon, String title, VoidCallback onTap,
      {String? endTitle,
      bool hasSwitch = false,
      bool switchValue = false,
      Function(bool)? onSwitchChanged}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(8),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Spacer(),
          if (hasSwitch)
            Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                endTitle ?? "",
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
        ]),
      ),
    );
  }
}
