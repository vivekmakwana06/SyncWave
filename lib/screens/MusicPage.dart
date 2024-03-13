import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sync_music/screens/music_detail_page.dart';
import '../theme/colors.dart';

class MusicPage extends StatefulWidget {
  final String? result;
  final bool? isCreatingHost;
  final bool? party_status;
  const MusicPage(
      {Key? key, this.result, this.party_status, this.isCreatingHost})
      : super(key: key);

  @override
  _MusicPageState createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with SingleTickerProviderStateMixin {
  int activeMenu1 = 0;
  int activeMenu2 = 0;

  late String _userName;
  int? result;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 1, vsync: this); // Change length to 1
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

                // Update party_status to false
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
    return Scaffold(
      backgroundColor: Color(0xFF1a1b1f),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1b1f),
        elevation: 0,
        leading: widget.isCreatingHost ?? false
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Color(0xff6157ff),
                ),
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
              ),

        titleSpacing: 0, // Set titleSpacing to 0
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
      floatingActionButton: widget.party_status != null && widget.party_status!
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // TrendingSong(),
          CustomCollection(0),
        ],
      ),
    );
  }

  //

  Widget CustomCollection(int tabIndex) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                // Song types (GridView)
                FutureBuilder<List<String>>(
                  future: getSongTypesFromFirestore(tabIndex),
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
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text("No song types available"),
                      );
                    } else {
                      List<String> songTypes = snapshot.data!;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                        ),
                        itemCount: songTypes.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (songTypes[index] == activeMenu1) {
                                  activeMenu1 = index;
                                } else {
                                  // activeMenu2 = index;
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: activeMenu1 == index
                                    ? null // Remove the color property
                                    : Colors.transparent,
                                border: Border.all(
                                  // color: primary,
                                  width: 2.0,
                                ),
                                gradient: activeMenu1 ==
                                        index // Set the gradient conditionally
                                    ? LinearGradient(
                                        begin: Alignment(-0.95, 0.0),
                                        end: Alignment(1.0, 0.0),
                                        colors: [
                                          Color(0xff6157ff),
                                          Color(0xffee49fd)
                                        ],
                                      )
                                    : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    songTypes[index],
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: activeMenu1 == index
                                          ? Colors.white
                                          : grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
                SizedBox(
                  height: 20,
                ),

                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("CustomCollection")
                      .get(),
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
                        child: Text("No songs available"),
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
                                    ),
                                    SizedBox(height: 10),
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
                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            onPressed: () {
                                              // Handle delete functionality here
                                              deleteSong(context,
                                                  snapshot.data!.docs[i].id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5),
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

  Future<List<String>> getSongTypesFromFirestore(int index) async {
    // Fetch song types from Firestore based on the index
    try {
      DocumentSnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("song_types")
              .doc(index == 0 ? "type1" : "")
              .get();
      List<String> songTypes =
          List<String>.from(querySnapshot.data()!['types']);
      return songTypes;
    } catch (error) {
      print("Error fetching song types: $error");
      return [];
    }
  }

  Widget getSongTypeListView(List<String> songTypes, int activeMenu) {
    final int itemsPerLine = 2;

    return SizedBox(
      child: Wrap(
        alignment: WrapAlignment.start,
        runSpacing: 10.0,
        spacing: 16.0, // Adjust the spacing between items here
        children: List.generate(songTypes.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 25),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (songTypes[index] == activeMenu1) {
                    activeMenu1 = index;
                  } else {
                    // activeMenu2 = index;
                  }
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    songTypes[index],
                    style: TextStyle(
                      fontSize: 15,
                      color: activeMenu == index ? Color(0xff6157ff) : grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  activeMenu == index
                      ? Container(
                          width: 10,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Color(0xff6157ff),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget getSongListView() {
    return SizedBox(
      height: 300,
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection("songs").get(),
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
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No songs available"),
            );
          } else {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, i) {
                var imageUrl = snapshot.data!.docs[i]['image_url'].toString();

                if (imageUrl != "null") {
                  return Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition(
                                alignment: Alignment.bottomCenter,
                                child: MusicDetailPage(
                                  title: snapshot.data!.docs[i]['song_name']
                                      .toString(),
                                  color: Color(0xff6157ff),
                                  description: snapshot
                                      .data!.docs[i]['artist_name']
                                      .toString(),
                                  img: imageUrl,
                                  songUrl: snapshot.data!.docs[i]['song_url']
                                      .toString(),
                                ),
                                type: PageTransitionType.scale,
                              ),
                            );
                          },
                          child: Container(
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
                              padding:
                                  const EdgeInsets.only(top: 140, left: 140),
                              child: IconButton(
                                icon: Icon(Icons.delete),
                                color: Color.fromARGB(255, 255, 255, 255),
                                onPressed: () {
                                  // Handle delete functionality here
                                  deleteSong(
                                      context, snapshot.data!.docs[i].id);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const SizedBox(height: 20),
                        Container(
                          width: 180, // Adjust the width as needed
                          child: Text(
                            snapshot.data!.docs[i]['song_name'],
                            style: const TextStyle(
                              fontSize: 15,
                              color: white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2, // Set maxLines to the desired number
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 100,
                          child: Text(
                            snapshot.data!.docs[i]['artist_name'],
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container();
                }
              },
            );
          }
        },
      ),
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
    // Delete the song with the specified documentId from the CustomCollection collection
    try {
      await FirebaseFirestore.instance
          .collection("CustomCollection") // Update collection name here
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
