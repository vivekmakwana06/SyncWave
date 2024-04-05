import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sync_music/screens/music_detail_page.dart';

class Favorite extends StatefulWidget {
  final String? userId;

  const Favorite({Key? key, this.userId}) : super(key: key);

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  List<DocumentSnapshot>? _favoriteSongs; // Initialize _favoriteSongs

  late String _userName;
  late String? userId;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _userName = '';
    _loadUserName();
    fetchFavoriteSongs();
  }

  void fetchFavoriteSongs() async {
    List<DocumentSnapshot> favoriteSongs =
        await Provider.of<FavoriteSongsProvider>(context, listen: false)
            .getAllFavoriteSongs();
    setState(() {
      _favoriteSongs = favoriteSongs;
    });
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
                Icons.favorite,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorite Songs',
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
      body: _favoriteSongs != null
          ? RefreshIndicator(
              onRefresh: () async {
                fetchFavoriteSongs(); // Refresh the list of favorite songs
              },
              child: ListView.builder(
                itemCount: _favoriteSongs!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: InkWell(
                      onTap: () {
                        playSong(_favoriteSongs![index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: Colors.white,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                NetworkImage(_favoriteSongs![index]['imgUrl']),
                          ),
                          title: Text(
                            _favoriteSongs![index]['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(_favoriteSongs![index]['description']),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  void playSong(DocumentSnapshot song) {
    String title = song['title'];
    String description = song['description'];
    String imgUrl = song['imgUrl'];
    String songUrl = song['songUrl'];
    String documentId = song.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicDetailPage(
          title: title,
          description: description,
          color: Color(0xff6157ff),
          img: imgUrl,
          songUrl: songUrl,
          isFavorite: Provider.of<FavoriteSongsProvider>(context, listen: false)
              .favoriteSongs
              .contains(documentId),
          documentId: documentId,
        ),
      ),
    ).then((_) {
      // After navigating back, refresh the list of favorite songs
      fetchFavoriteSongs();
    });
  }
}
