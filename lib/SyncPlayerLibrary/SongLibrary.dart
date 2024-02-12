import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sync_music/SyncPlayerLibrary/SongLibraryPlayingpage.dart';

class YourScreen extends StatefulWidget {
  final String userEmail;
  final String generatedCode;

  const YourScreen(
      {super.key, required this.userEmail, required this.generatedCode});

  @override
  _YourScreenState createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('ArtistList').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Use shimmer effect while data is loading
            return EnhancedShimmerArtistList();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return buildArtistList(snapshot.data!.docs);
          }
        },
      ),
    );
  }

  Widget buildArtistList(List<QueryDocumentSnapshot> documents) {
    return Expanded(
      child: Container(
        color: const Color(0xFF1a1b1f),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: documents.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> artistData =
                documents[index].data() as Map<String, dynamic>;

            // Check if required fields exist in the document
            String artistName =
                artistData.containsKey('name') ? artistData['name'] : '';
            String artistImage =
                artistData.containsKey('image') ? artistData['image'] : '';

            List<String> musicIds = artistData.containsKey('listOfMusic')
                ? List<String>.from(artistData['listOfMusic'])
                : [];

            return buildArtistCard(context, artistName, artistImage, musicIds);
          },
        ),
      ),
    );
  }

  Widget buildArtistCard(BuildContext context, String artistName,
      String artistImage, List<String> musicIds) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return FractionallySizedBox(
              heightFactor: 1.0,
              child: MusicDetailsPage(
                artistName: artistName,
                artistImage: artistImage,
                musicIds: musicIds,
              ),
            );
          },
        );
      },
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 110,
              height: 110,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: artistImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(artistImage),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage("assets/placeholder_image.jpg"),
                        fit: BoxFit.cover,
                      ),
              ),
              // child: Column(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [

              //     const SizedBox(height: 8),
              //   ],
              // ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text(
                artistName,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer effect for the artist list
class EnhancedShimmerArtistList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2D2D2D), // Dark gray background color
      highlightColor: const Color(0xFF3D3D3D), // Light gray shimmer color
      period: const Duration(
          milliseconds: 1000), // Controls the speed of the shimmer effect
      child: Container(
        color: const Color(0xFF1a1b1f),
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5, // Adjust the number of shimmer items
          itemBuilder: (context, index) {
            return Container(
              width: 110,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors
                          .grey, // Add a background color to the shimmer item
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors
                          .grey, // Add a background color to the shimmer item
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MusicDetailsPage extends StatelessWidget {
  final List<String> musicIds;
  final String artistImage;
  final String artistName;

  MusicDetailsPage({
    required this.musicIds,
    required this.artistImage,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(artistImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: const Color(0xFF1a1b1f)
              .withOpacity(0.95), // Adjust the opacity as needed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        // ignore: use_full_hex_values_for_flutter_colors
                        color: Color(0xfffffffff),
                      ))
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Hero(
                tag: artistImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      artistImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Stylish card to display the artist name
              Text(
                artistName,
                style: const TextStyle(
                  fontSize: 28,
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchMusicDetails(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ShimmerLoadingList();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      List<Map<String, dynamic>> musicDetails = snapshot.data!;
                      return ListView.builder(
                        itemCount: musicDetails.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) {
                                  return FractionallySizedBox(
                                    heightFactor:
                                        1.0, // Adjust the factor as needed
                                    child: MusicPlayPage(
                                      musicName: musicDetails[index]['data']
                                          ['name'],
                                      code: artistImage,
                                      downloadUrl: musicDetails[index]['data']
                                          ['file'],
                                      documentId: musicDetails[index]
                                          ['musicId'],
                                    ),
                                  );
                                },
                              );
                            },
                            leading: const CircleAvatar(
                              backgroundColor:
                                  Color(0xFF121640), // Accent color
                              radius: 18,
                              child: Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            title: SizedBox(
                              width: 150, // Adjust the width as needed
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  '${musicDetails[index]['data']['name']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            subtitle: Text(artistName),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchMusicDetails() async {
    List<Map<String, dynamic>> musicDetails = [];

    // Fetch data for each music ID
    for (String musicId in musicIds) {
      DocumentSnapshot musicDocument = await FirebaseFirestore.instance
          .collection('Music')
          .doc(musicId)
          .get();

      if (musicDocument.exists) {
        // If the document exists, add its data to the list
        musicDetails.add({
          'musicId': musicId,
          'data': musicDocument.data(),
        });

        // Print the data for each music ID
      }
    }

    return musicDetails;
  }

  // ignore: non_constant_identifier_names
  Widget ShimmerLoadingList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 7, // Number of shimmer loading items
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[400]!,
                shape: BoxShape.circle,
              ),
            ),
            title: Container(
              width: 150,
              height: 20,
              // Background color for shimmer
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
            ),
            subtitle: Container(
              width: 100,
              height: 16,
              margin: const EdgeInsets.only(top: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
