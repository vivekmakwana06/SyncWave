import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sync_music/screens/SongLibrary.dart';
import 'package:sync_music/screens/music_detail_page.dart';

import '../json/songs_json.dart';
import '../theme/colors.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({Key? key}) : super(key: key);

  @override
  _MusicPageState createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with SingleTickerProviderStateMixin {
  int activeMenu1 = 0;
  int activeMenu2 = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

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
              Icons.music_note,
              color: Color.fromARGB(255, 236, 146, 3),
              size: 30,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Discovery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Let\'s listen to something cool today',
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
            Tab(text: 'Trending Song'),
            Tab(text: 'User Collection'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TrendingSong(),
          CustomCollection(0),
        ],
      ),
    );
  }

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
                          color: primary,
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
                                    ? primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: primary,
                                  width: 2.0,
                                ),
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
                  future: FirebaseFirestore.instance.collection("songs").get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: primary,
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
                                        color: const Color(0xFF58546c),
                                        description: snapshot
                                            .data!.docs[i]['artist_name']
                                            .toString(),
                                        img: imageUrl,
                                        songUrl: snapshot
                                            .data!.docs[i]['song_url']
                                            .toString(),
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
                                        color: primary,
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

  Widget TrendingSong() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 650,
            color: const Color(0xFF1a1b1f),
            child: Column(
              children: [
                const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 24, top: 16),
                      child: Text(
                        "Enjoy The Trending Songs🔥",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  flex: 7,
                  child: YourScreen(),
                ),
                SizedBox(
                  height: 20,
                ),
                const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 24, top: 16),
                      child: Text(
                        "Famous Artist Playlist💖",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  flex: 7,
                  child: YourScreen(),
                ),
                Expanded(
                  flex: 14,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF1a1b1f),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final int itemsPerLine = 2; // Adjust the number of items per line here

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
                      color: activeMenu == index ? primary : grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  activeMenu == index
                      ? Container(
                          width: 10,
                          height: 3,
                          decoration: BoxDecoration(
                            color: primary,
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
                color: primary,
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
                                  color: const Color(0xFF58546c),
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
                              color: primary,
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
    // Delete the song with the specified documentId
    try {
      await FirebaseFirestore.instance
          .collection("songs")
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
