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
import 'package:sync_music/screens/PlaylistPage.dart';
import 'package:sync_music/screens/downloadSong.dart';
import 'package:sync_music/screens/favorite.dart';

enum Availability { loading, available, unavailable }

class Upload extends StatefulWidget {
  const Upload({Key? key}) : super(key: key);

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with SingleTickerProviderStateMixin {
  TextEditingController songName = TextEditingController();
  TextEditingController artistName = TextEditingController();
  double uploadProgress = 0.0;

  late TabController _tabController;

  late String imagepath, songPath;
  late Reference reference;
  late String _userName;
  var imageDownloadUrl, songDownloadUrl;
  PlatformFile? imageResult, songResult;

  Availability _availability = Availability.loading;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userName = ''; // Set an initial value
    _loadUserName();
  }

  Future<String?> getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.email;
    }
    return null;
  }

// ...

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
    setState(() {
      imageResult = result!.files.first;
      File image = File(imageResult!.path!); // Use null-aware operator here
      imagepath = basename(image.path.toString());
      uploadImageFile(image.readAsBytesSync(), imagepath);
    });
  }

  void uploadImageFile(Uint8List image, String imagepath) async {
    reference = FirebaseStorage.instance.ref().child(imagepath);
    UploadTask uploadTask = reference.putData(image);

    TaskSnapshot taskSnapshot = await uploadTask;

    // Get the download URL
    imageDownloadUrl = await taskSnapshot.ref.getDownloadURL();

    // Trigger a rebuild to update the UI with the selected image
    setState(() {});
  }

  uploadSongFile(Uint8List song, String songPath) async {
    reference = FirebaseStorage.instance.ref().child(songPath);
    UploadTask uploadTask = reference.putData(song);
    uploadTask.whenComplete(() async {
      void uploadSongFile(Uint8List song, String songPath) async {
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

        // Reset uploadProgress after completing the upload
        setState(() {
          uploadProgress = 0.0;
        });
      }

      try {
        songDownloadUrl = await reference.getDownloadURL();
      } catch (onError) {
        const Text("Errors");
      }
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

  void finalUpload(BuildContext context) async {
    if (songResult != null) {
      try {
        File songFile = File(songResult!.path!);

        var data = {
          "song_name": basename(songFile.path),
          "artist_name": artistName.text,
          "song_url": songDownloadUrl.toString(),
          "image_url": imageDownloadUrl.toString(),
        };

        await FirebaseFirestore.instance.collection("songs").doc().set(data);

        // Reset the information after successful upload
        setState(() {
          songName.text = "";
          artistName.text = "";
          imageDownloadUrl = null;
          songDownloadUrl = null;
          songResult = null;
        });
      } catch (error) {
        // Handle upload errors
        print("Upload error: $error");

        // Show an error message
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
      // Show an error message if no song is selected
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
        backgroundColor: Color(0xFF1a1b1f),
        elevation: 0,
        title: const Row(
          children: [
            SizedBox(
              width: 10,
              height: 5,
            ),
            Icon(
              Icons.person,
              color: Color.fromARGB(255, 236, 146, 3),
              size: 38,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'User Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'User Profile uder all functionality..',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Color.fromARGB(255, 236, 146, 3),
          tabs: [
            Tab(text: 'Profile'),
            Tab(text: 'Custom Collection'),
          ],
        ),
      ),
      backgroundColor: Color(0xFF1a1b1f),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    // Display the welcome message
                    Text(
                      'Welcome to,', // Use the user's name here
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 25,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '$_userName',
                      style: GoogleFonts.nunito(
                        color: Color.fromARGB(255, 236, 146, 3),
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: 50),
                    Divider(thickness: .4),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Favorite()),
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
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Playlist()),
                          );
                        },
                        child: Container(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 10,
                              ),
                              Icon(
                                Icons.playlist_add,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Playlist Song',
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
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DownloadedSong()),
                          );
                        },
                        child: Container(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 10,
                              ),
                              Icon(
                                Icons.download,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Download Song',
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
                      height: 65,
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
                        primary: Colors.red, // Set the button color
                        onPrimary: Colors.white, // Set the text color
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
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 10,
                    ),
                    // Divider(thickness: .1),
                    ElevatedButton(
                      onPressed: () => selectImage(),
                      child: const Text(
                        "Select Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 236, 146, 3),
                        onPrimary: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    Divider(thickness: .4),
                    ElevatedButton(
                      onPressed: () => selectSong(),
                      child: const Text(
                        "Select Song",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 236, 146, 3),
                        onPrimary: Colors.white,
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
                    const SizedBox(height: 20),
                    TextField(
                      controller: artistName,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Enter Artist Name",
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 236, 146, 3),
                              width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 236, 146, 3),
                              width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 236, 146, 3),
                              width: 3),
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(thickness: .4),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => finalUpload(context),
                      child: const Text(
                        "Upload",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 236, 146, 3),
                        onPrimary: Colors.white,
                      ),
                    ),
                    // const SizedBox(height: 20),
                    // uploadProgress > 0
                    //     ? Column(
                    //         children: [
                    //           LinearProgressIndicator(
                    //             value: uploadProgress,
                    //             backgroundColor: Colors.grey,
                    //             color: Color.fromARGB(255, 236, 146, 3),
                    //           ),
                    //           const SizedBox(height: 10),
                    //           Text(
                    //             "Upload Progress: ${(uploadProgress * 100).toStringAsFixed(2)}%",
                    //             style: TextStyle(
                    //               color: Colors.white,
                    //               fontWeight: FontWeight.bold,
                    //             ),
                    //           ),
                    //           const SizedBox(height: 10),
                    //         ],
                    //       )
                    //     : Container(),
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
