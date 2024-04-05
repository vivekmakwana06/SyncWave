import 'package:flutter/material.dart';
import 'package:sync_music/screens/music_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:page_transition/page_transition.dart';
import '../theme/colors.dart';

class Collection extends StatefulWidget {
  final String? result;
  final bool? isCreatingHost;
  final bool? party_status;
  const Collection(
      {Key? key, this.result, this.party_status, this.isCreatingHost})
      : super(key: key);

  @override
  _CollectionState createState() => _CollectionState();
}

class _CollectionState extends State<Collection>
    with SingleTickerProviderStateMixin {
  int activeMenu1 = 0;
  int activeMenu2 = 0;

  late String _userName;
  int? result;
  late TabController _tabController;
  late String? userId;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 1, vsync: this); // Change length to 1
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

  void exitHost() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you want to exit the host?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pop(context); // Navigate back to the previous page

                // Update party_status to false in party collection
                await FirebaseFirestore.instance
                    .collection("party")
                    .doc(widget
                        .result!) // Assuming widget.result contains the party document ID
                    .update({'party_status': false});
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        exitHost(); // Call exitHost() when the back button is pressed
        return true; // Return true to allow the back navigation
      },
      child: Scaffold(
        backgroundColor: Color(0xFF221e3b),
        appBar: AppBar(
          backgroundColor: Color(0xFF221e3b),
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              SizedBox(
                width: 25,
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
                  Icons.collections,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collection',
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
        floatingActionButton:
            widget.party_status != null && widget.party_status!
                ? Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      gradient: LinearGradient(
                        begin: Alignment(-0.95, 0.0),
                        end: Alignment(1.0, 0.0),
                        colors: [Color(0xff6157ff), Color(0xffee49fd)],
                      ),
                    ),
                    child: FloatingActionButton(
                      onPressed: () {
                        exitHost();
                      },
                      backgroundColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, right: 10),
                        child: Text(
                          'Exist Host',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 245, 245, 245),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: TabBarView(
            controller: _tabController,
            children: [
              CustomCollection(0, _userName, userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget CustomCollection(int tabIndex, String userEmail, String? userId) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                // Song types (GridView)
                Visibility(
                  visible: widget.isCreatingHost == true,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      gradient: LinearGradient(
                        begin: Alignment(-0.95, 0.0),
                        end: Alignment(1.0, 0.0),
                        colors: [Color(0xff6157ff), Color(0xffee49fd)],
                      ),
                    ),
                    child: Text(
                      'Host: ${widget.result}', // Display the result here
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: 20,
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(userId)
                      .collection("CustomCollection")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff6157ff),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text("Error: ${snapshot.error}"),
                      );
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "No songs available",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 25),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: .6,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: snapshot.data!.docs.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, i) {
                            var imageUrl =
                                snapshot.data!.docs[i]['image_url'].toString();
                            var documentId = snapshot.data!.docs[i].id;

                            if (imageUrl != "null") {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageTransition(
                                      alignment: Alignment.bottomCenter,
                                      child: MusicDetailPage(
                                        title: snapshot
                                            .data!.docs[i]['song_name']
                                            .toString(),
                                        color: Color(0xff6157ff),
                                        description: snapshot
                                            .data!.docs[i]['artist_name']
                                            .toString(),
                                        img: imageUrl,
                                        songUrl: snapshot
                                            .data!.docs[i]['song_url']
                                            .toString(),
                                        result: widget.result,
                                        isCreatingHost:
                                            widget.isCreatingHost ?? false,
                                        documentId: documentId,
                                      ),
                                      type: PageTransitionType.scale,
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                        color: Color(0xff6157ff),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 115, bottom: 150),
                                        child: IconButton(
                                          icon: Icon(Icons.delete),
                                          color: Color.fromARGB(255, 216, 1, 1),
                                          iconSize: 28,
                                          onPressed: () {
                                            // Handle delete functionality here
                                            deleteSong(context,
                                                snapshot.data!.docs[i].id);
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              snapshot.data!.docs[i]
                                                  ['song_name'],
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        snapshot.data!.docs[i]['artist_name'],
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void deleteSong(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this song?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Close the dialog and proceed with deletion
                Navigator.of(context).pop();
                await performDelete(documentId);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> performDelete(String documentId) async {
    // Delete the song with the specified documentId from the user's CustomCollection collection
    try {
      // Assuming userId is not null
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("CustomCollection")
          .doc(documentId)
          .delete();
      print("Song deleted successfully!");
      // Trigger a rebuild of the widget tree
      setState(() {});
    } catch (error) {
      print("Error deleting song: $error");
    }
  }
}
