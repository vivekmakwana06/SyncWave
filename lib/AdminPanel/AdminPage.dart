import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:sync_music/screens/LoginRegisterPage.dart';
import 'package:lottie/lottie.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Widget> textFields = [];
  int index = 1;
  late Reference reference;
  late String imagepath, songPath;
  var imageDownloadUrl, songDownloadUrl;
  PlatformFile? imageResult, songResult;
  Future<String?> _uploadComplete = Future.value(null);

  List<String> uploadedMusicNames = [];

  void addTextField() {
    bool isTickMarkIcon = index > 1 && _uploadComplete != null;

    textFields.add(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (!isTickMarkIcon) {
                        pickFile();
                      }
                    },
                    onLongPress: () {
                      if (!isTickMarkIcon) {
                        pickFile();
                      }
                    },
                    child: isTickMarkIcon
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 70,
                          )
                        : Lottie.asset(
                            'assets/addfile.json',
                            width: 70,
                            height: 70,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Expanded(
                      child: FutureBuilder<String?>(
                        future: _uploadComplete,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.data != null) {
                            // Add the uploaded music name to the list
                            uploadedMusicNames.add(snapshot.data!);

                            return Container(
                              width: 500, // Adjust the width as needed
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${snapshot.data}',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    index++;
  }

  bool showTextField = false;
  List<ColorData> colorData = [];
  TextEditingController colorCodeController = TextEditingController();
  TextEditingController musicNameController = TextEditingController();
  TextEditingController nameOfMusicController = TextEditingController();
  bool isUploading = false;
  double uploadProgress = 0.0; // Track the upload progress

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    loadColorData();
    addTextField(); // Initially add one text field
  }

  Future<void> loadColorData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/colors.json');
      final jsonData = json.decode(jsonString);

      List<ColorData> colors = [];
      for (var item in jsonData) {
        colors.add(ColorData(name: item['name'], hex: item['hex']));
      }

      setState(() {
        colorData = colors;
      });
    } catch (e) {
      print('Error loading color data: $e');
    }
  }

  String _currentFolderId = '';

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File selectedFile = File(result.files.single.path!);

        setState(() {
          isUploading = true;
          uploadProgress = 0.0;
        });

        String fileName = DateTime.now().millisecondsSinceEpoch.toString();

        final firebase_storage.Reference reference =
            firebase_storage.FirebaseStorage.instance.ref('uploads/$fileName');

        final firebase_storage.UploadTask uploadTask =
            reference.putFile(selectedFile);

        final StreamSubscription<firebase_storage.TaskSnapshot>
            streamSubscription = uploadTask.snapshotEvents.listen((event) {
          setState(() {
            uploadProgress = event.bytesTransferred / event.totalBytes;
          });
        });

        await uploadTask;

        streamSubscription.cancel();

        String downloadUrl = await reference.getDownloadURL();
        String musicName = musicNameController.text;
        String audioName = nameOfMusicController.text;
        String audioFile = downloadUrl;
        String fileNameWithoutExtension =
            path.basenameWithoutExtension(selectedFile.path ?? '');

        // Set the uploaded song name to the _uploadComplete variable
        setState(() {
          _uploadComplete = Future.value(fileNameWithoutExtension);
        });

        DocumentReference musicDocumentReference =
            await firestore.collection('Music').add({
          'name': fileNameWithoutExtension,
          'file': audioFile,
        });

        String musicDocumentId = musicDocumentReference.id;

        // Check if there is a current folder ID
        if (_currentFolderId == null || _currentFolderId!.isEmpty) {
          // If no current folder ID, create a new folder
          DocumentReference folderDocumentReference =
              await firestore.collection('ArtistList').add({
            'name': musicName,
            'listOfMusic': [musicDocumentId],
            'image': imageDownloadUrl, // Use the current image URL
          });

          // Set the current folder ID to the newly created folder
          _currentFolderId = folderDocumentReference.id;
        } else {
          // If there is a current folder ID, update the existing folder
          DocumentReference folderDocumentReference =
              firestore.collection('ArtistList').doc(_currentFolderId!);

          // Update the existing folder with the new music details and the current image URL
          await folderDocumentReference.update({
            'listOfMusic': FieldValue.arrayUnion([musicDocumentId]),
            'image': imageDownloadUrl, // Use the current image URL
          });

          print('Audio uploaded successfully!');
        }

        // Add the uploaded music name to the list
        uploadedMusicNames.add(fileNameWithoutExtension);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File uploaded successfully!',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 236, 146, 3),
                fontSize: 15,
              ),
            ),
          ),
        );

        setState(() {
          isUploading = false;
          uploadProgress = 0.0;
          // Add a new text field for the next song
          addTextField();
        });
      } else {
        // User canceled the file picker
      }
    } catch (e) {
      print('Error picking file: $e');
      // Handle the error as needed
    }
  }

  Future<void> uploadDataToFirebase() async {
    try {
      // Check if there is at least one text field
      if (textFields.isNotEmpty) {
        // Clear the form fields
        clearPickedImage();
        musicNameController.clear();

        // Clear the uploaded music names list
        uploadedMusicNames.clear();

        // Reset the text fields list
        // setState(() {
        //   textFields.clear();
        //   index = 1;
        // });

        // Reset the current folder ID
        _currentFolderId = '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data uploaded successfully!',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 236, 146, 3),
                fontSize: 15,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least one song to upload!'),
          ),
        );
      }
    } catch (e) {
      print('Error uploading data: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error uploading data. Please try again.',
            style: GoogleFonts.kanit(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 236, 3, 3),
              fontSize: 15,
            ),
          ),
        ),
      );
    }
  }

  void clearPickedImage() {
    setState(() {
      imageDownloadUrl = null;
    });
  }

  void selectImage() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null) {
        File selectedImage = File(result.files.single.path!);
        await uploadImageFile(selectedImage);
      } else {
        // User canceled the file picker
      }
    } catch (e) {
      print('Error selecting image: $e');
    }
  }

  Future<void> uploadImageFile(File image) async {
    try {
      setState(() {
        isUploading = true;
        uploadProgress = 0.0;
      });

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String fileExtension =
          path.extension(image.path).toLowerCase().substring(1);

      // Check if the file is an image with a valid format
      if (['jpeg', 'png', 'jpg'].contains(fileExtension)) {
        Reference reference = FirebaseStorage.instance
            .ref()
            .child('uploads/image/$fileName.$fileExtension');

        UploadTask uploadTask = reference.putFile(image);

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        setState(() {
          imageDownloadUrl = downloadUrl;
          isUploading = false;
          uploadProgress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image uploaded successfully!',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 236, 146, 3),
                fontSize: 15,
              ),
            ),
          ),
        );

        // Update the image URL in the 'ArtistList' collection only if it's an image
        if (_isImageFile(fileExtension)) {
          await updateArtistListImage(downloadUrl);
        }

        // Check if there is a current folder ID
        if (_currentFolderId == null || _currentFolderId!.isEmpty) {
          // If no current folder ID, create a new folder
          DocumentReference folderDocumentReference =
              await firestore.collection('ArtistList').add({
            'name': musicNameController.text,
            'image': _isImageFile(fileExtension)
                ? downloadUrl
                : '', // This should be the correct image download URL
          });

          // Set the current folder ID to the newly created folder
          _currentFolderId = folderDocumentReference.id;
        } else {
          // If there is a current folder ID, update the existing folder
          DocumentReference folderDocumentReference =
              firestore.collection('ArtistList').doc(_currentFolderId!);

          // Update the existing folder with the new image URL
          await folderDocumentReference.update({
            'image': _isImageFile(fileExtension)
                ? downloadUrl
                : '', // This should be the correct image download URL
          });

          print('Image URL updated successfully in ArtistList collection!');
        }
      } else {
        // Handle the case where the selected file is not an image with a valid format
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid image format. Please select a valid image (jpeg, png, jpg).',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 236, 3, 3),
                fontSize: 15,
              ),
            ),
          ),
        );
        setState(() {
          isUploading = false;
          uploadProgress = 0.0;
        });
      }
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
      });
    }
  }

  bool _isImageFile(String fileExtension) {
    return ['jpeg', 'png', 'jpg'].contains(fileExtension);
  }

  Future<void> updateArtistListImage(String imageUrl) async {
    try {
      if (_currentFolderId != null && _currentFolderId.isNotEmpty) {
        // Update the 'image' field in 'ArtistList' using the current folder ID
        await firestore.collection('ArtistList').doc(_currentFolderId!).update({
          'image': imageUrl,
        });

        print('Image URL updated successfully in ArtistList collection!');
      }
    } catch (e) {
      print('Error updating image URL in ArtistList collection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Perform logout
            await FirebaseAuth.instance.signOut();

            // Navigate to the login page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AuthGate()),
            );
          },
          child: Icon(
            Icons.logout,
            size: 30,
            color: Colors.red,
          )),
      body: Container(
        height: double.infinity,
        color: const Color(0xFF1a1b1f),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(
                  height: 40,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 80),
                  child: const Row(
                    children: [
                      Icon(
                        size: 38,
                        Icons.admin_panel_settings,
                        color: Color.fromARGB(255, 236, 146, 3),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Page',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFFFFF),
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Admin Side',
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
                const SizedBox(height: 90),
                const Text(
                  'Name Of Folder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: musicNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Enter Your Collection Name',
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w200,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Select Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    selectImage();
                  },
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageDownloadUrl != null
                            ? Image.network(imageDownloadUrl).image
                            : AssetImage("assets/logo.png"),
                        fit: BoxFit.cover,
                      ),
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'List Of Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    '${(uploadProgress * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 236, 146, 3),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...textFields,
                const SizedBox(
                  width: 40,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        uploadDataToFirebase();
                      },
                      child: const Text(
                        "Upload",
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 236, 146, 3),
                        onPrimary: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ColorData {
  final String name;
  final String hex;

  ColorData({required this.name, required this.hex});
}
