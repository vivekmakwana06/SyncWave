import 'dart:async';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart' hide LoopMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicDetailPage extends StatefulWidget {
  final String? title;
  final String? description;
  final Color? color;
  final String? img;
  final String? songUrl;
  final bool? partyStatus;
  final String? result;
  final bool? syncMusicEnabled;
  final bool? isCreatingHost;
  final String? documentId;
  final bool? isFavorite;

  const MusicDetailPage({
    Key? key,
    this.title,
    this.result,
    this.partyStatus,
    this.description,
    this.color,
    this.img,
    this.songUrl,
    this.isCreatingHost,
    this.syncMusicEnabled,
    this.documentId,
    this.isFavorite,
  }) : super(key: key);

  @override
  _MusicDetailPageState createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage>
    with SingleTickerProviderStateMixin {
  late final AssetsAudioPlayer assetsAudioPlayer;
  late final AudioPlayer player;
  late String _userName;
  int? generatedCode;
  bool isPlaying = true;
  bool syncMusic = false;
  Random random = Random();
  bool isFavorite = false;
  Duration duration = const Duration();
  LoopMode playerLoopMode = LoopMode.one;

  int timeDifference = 0;

  late String? userId;
  Duration position = const Duration();
  late FirebaseFirestore firestore;
  late StreamSubscription<DocumentSnapshot> subscription;

  late AnimationController _rotationController;
  bool musicLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus(widget.documentId.toString());
    isFavorite = widget.isFavorite ?? false;
    _userName = '';
    _loadUserName();
    assetsAudioPlayer = AssetsAudioPlayer();
    player = AudioPlayer();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    firestore = FirebaseFirestore.instance;

    subscription = firestore
        .collection("sync")
        .doc(widget.result.toString())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        if (event.data()!.containsKey("currentPosition")) {
          setState(() {
            position = Duration(milliseconds: event["currentPosition"]);
            isPlaying = event["isPlaying"];
          });
        }
      }
    });

    assetsAudioPlayer.current.listen((playing) {
      setState(() {
        duration = playing!.audio.duration;
        musicLoaded = true;
      });
    });

    assetsAudioPlayer.isPlaying.listen((isPlaying) {
      if (isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    playMusic(widget.songUrl!);
  }

  void playMusic(String url) async {
    final audio = Audio.network(
      url,
      metas: Metas(
        title: widget.title,
        artist: widget.description,
        image: MetasImage.network(widget.img!),
      ),
    );

    assetsAudioPlayer.open(
      audio,
      showNotification: true,
      playInBackground: PlayInBackground.enabled,
      autoStart: true,
    );

    assetsAudioPlayer.currentPosition.listen((event) {
      setState(() {
        position = event;
        if (syncMusic) {
          updateSyncDocument();
        }
      });
    });

    assetsAudioPlayer.current.listen((event) {
      setState(() {
        duration = event!.audio.duration;
      });
    });

    assetsAudioPlayer.isPlaying.listen((event) {
      setState(() {
        isPlaying = event;
      });
    });

    if (widget.isCreatingHost ?? false) {
      syncMusic = true;
      await firestore.collection("sync").doc(widget.result.toString()).set({
        'musicName': widget.title,
        'artistName': widget.description,
        'songUrl': widget.songUrl,
        'imgUrl': widget.img,
        'currentPosition': 0,
        'isPlaying': true,
      });
      openDialog("Sync music successfully");
    }
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

  void handlePlayPause() async {
    if (isPlaying) {
      await assetsAudioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await assetsAudioPlayer.play();
      setState(() {
        isPlaying = true;
      });
    }
    updateSyncDocument();
    updatePlaybackState(isPlaying);
  }

  void updateSyncDocument() {
    final docSync = firestore.collection("sync").doc(widget.result.toString());
    final adjustedPosition = position.inMilliseconds + timeDifference;
    docSync.update({
      'currentPosition': adjustedPosition,
      'isPlaying': isPlaying,
    });
  }

  void seekMusic(Duration newPosition) {
    assetsAudioPlayer.seek(newPosition);
    position = newPosition;
    updateSyncDocument();
  }

  void skipForward() {
    Duration newPosition = position + const Duration(seconds: 10);
    if (newPosition > duration) {
      newPosition = duration;
    }
    assetsAudioPlayer.seek(newPosition);
    updateSyncDocument();
  }

  void skipBackward() {
    Duration newPosition = position - const Duration(seconds: 10);
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    }
    assetsAudioPlayer.seek(newPosition);
    updateSyncDocument();
  }

  void updateSyncOption(bool value) {
    syncMusic = value;
    if (syncMusic) {
      updateSyncDocument();
    }
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }

  @override
  void dispose() {
    subscription.cancel();
    assetsAudioPlayer.dispose();
    player.dispose();
    _rotationController.dispose();
    updatePlaybackState(false);
    super.dispose();
  }

  void updatePlaybackState(bool isPlaying) {
    final docSync = firestore.collection("sync").doc(widget.result.toString());
    docSync.update({
      'isPlaying': isPlaying,
    });
  }

  Future<void> toggleFavorite(String documentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favoriteMusic') ?? [];

    if (favorites.contains(documentId)) {
      favorites.remove(documentId);
    } else {
      favorites.add(documentId);
    }

    await prefs.setStringList('favoriteMusic', favorites);
    Provider.of<FavoriteSongsProvider>(context, listen: false)
        .notifyListeners();
  }

  void _loadFavoriteStatus(String documentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFavorite = prefs.getBool(documentId) ?? false;
    setState(() {
      this.isFavorite = isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      appBar: getAppBar(),
      body: getBody(),
    );
  }

  getAppBar() {
    return AppBar(
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
      backgroundColor: Color(0xFF221e3b),
      elevation: 0,
    );
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;
    return Consumer<FavoriteSongsProvider>(
        builder: (context, favoriteSongsProvider, _) {
      bool isFavorite =
          favoriteSongsProvider.favoriteSongs.contains(widget.result);
      return SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                  child: Container(
                    width: size.width - 100,
                    height: size.width - 100,
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          color: widget.color!,
                          blurRadius: 50,
                          spreadRadius: 5,
                          offset: const Offset(-10, 40))
                    ], borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                  child: Container(
                    width: size.width - 60,
                    height: size.width - 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, widget.color!],
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.img!),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: musicLoaded
                            ? RotationTransition(
                                turns: Tween(begin: 0.0, end: 1.0)
                                    .animate(_rotationController),
                                child: CircleAvatar(
                                  maxRadius: 80,
                                  backgroundImage: widget.img is String &&
                                          widget.img!.isNotEmpty
                                      ? NetworkImage(widget.img!)
                                          as ImageProvider<Object>?
                                      : AssetImage('assets/syncci.png'),
                                  backgroundColor: Colors.transparent,
                                  child: widget.img is String &&
                                          widget.img!.isNotEmpty
                                      ? null
                                      : const Icon(
                                          color: Colors.white,
                                          Icons.music_note_rounded,
                                          size: 60,
                                        ),
                                ),
                              )
                            : Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Color(0xff6157ff),
                                child: const CircleAvatar(
                                  maxRadius: 80,
                                ),
                              ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: SizedBox(
                width: size.width - 80,
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              widget.title!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            height: 20,
                            width: 300,
                            child: Flexible(
                              flex: 1,
                              child: Text(
                                widget.description!,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 270),
              child: Container(
                height: 42,
                width: 50,
                child: CircleAvatar(
                  backgroundColor: Color.fromARGB(255, 52, 50, 50),
                  child: Consumer<FavoriteSongsProvider>(
                    builder: (context, favoriteSongsProvider, _) {
                      bool isFavorite = favoriteSongsProvider.favoriteSongs
                          .contains(widget.documentId);
                      return IconButton(
                        icon: Icon(
                          Icons.favorite,
                          size: 30,
                          color: isFavorite ? Colors.red : Colors.white,
                        ),
                        onPressed: () {
                          favoriteSongsProvider.toggleFavorite(
                            widget.documentId.toString(),
                            title: widget.title ?? '',
                            description: widget.description,
                            imgUrl: widget.img,
                            songUrl: widget.songUrl,
                          );
                          setState(() {
                            isFavorite = !isFavorite;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Slider.adaptive(
              activeColor: Color(0xff6157ff),
              value: position.inSeconds
                  .toDouble()
                  .clamp(0.0, duration.inSeconds.toDouble()),
              max: duration.inSeconds.toDouble(),
              min: 0.0,
              onChanged: (value) {
                // setState(() {
                //   position = Duration(seconds: value.toInt());
                // });
                // seekMusic(Duration(seconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatTime(position),
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  Text(
                    formatTime(duration - position),
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: !(widget.isCreatingHost ?? false),
                  child: IconButton(
                    onPressed: () {
                      skipBackward();
                    },
                    icon: Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                // Play/Pause Button
                IconButton(
                  iconSize: 100,
                  icon: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-0.95, 0.0),
                        end: Alignment(1.0, 0.0),
                        colors: [Color(0xff6157ff), Color(0xffee49fd)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    handlePlayPause();
                  },
                ),
                SizedBox(
                  width: 20,
                ),
                Visibility(
                  visible: !(widget.isCreatingHost ?? false),
                  child: IconButton(
                    onPressed: () {
                      skipForward();
                    },
                    icon: Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                if (widget.isCreatingHost ?? false) {
                  syncMusic = true;
                  await firestore
                      .collection("sync")
                      .doc(widget.result.toString())
                      .set({
                    'musicName': widget.title,
                    'artistName': widget.description,
                    'songUrl': widget.songUrl,
                    'imgUrl': widget.img,
                  });
                  openDialog("Sync music successfully");
                } else {}
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [],
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  Future openDialog(String message) async {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Color(0xff6157ff),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class FavoriteSongsProvider extends ChangeNotifier {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late List<String> _favoriteSongs;
  late String _userId;

  FavoriteSongsProvider(String userId) {
    _userId = userId;
    _favoriteSongs = [];
    fetchFavoriteSongs();
  }

  List<String> get favoriteSongs => _favoriteSongs;
  String get userId => _userId;

  Future<List<DocumentSnapshot>> getAllFavoriteSongs() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection('favoriteMusic')
        .get();
    return querySnapshot.docs;
  }

  void fetchFavoriteSongs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favoriteMusic') ?? [];

    // Fetch favorites from Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection('favoriteMusic')
        .get();

    List<String> firestoreFavorites = querySnapshot.docs
        .map((doc) => doc.id)
        .toList(); // Use doc.id to get the document ID

    // Combine favorites from Firestore and local storage
    _favoriteSongs = [...favorites, ...firestoreFavorites].toSet().toList();

    notifyListeners();
  }

  void toggleFavorite(
    String documentId, {
    String? title,
    String? description,
    String? imgUrl,
    String? songUrl,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favoriteMusic') ?? [];

    if (favorites.contains(documentId)) {
      favorites.remove(documentId);
      removeFromFavoritesFirestore(documentId);
    } else {
      favorites.add(documentId);
      addToFavoritesFirestore(documentId, title, description, imgUrl, songUrl);
    }

    await prefs.setStringList('favoriteMusic', favorites);

    // Update the favorite status locally
    if (_favoriteSongs.contains(documentId)) {
      _favoriteSongs.remove(documentId);
    } else {
      _favoriteSongs.add(documentId);
    }

    notifyListeners(); // Notify listeners about the change in favorite status
  }

  void removeFromFavoritesFirestore(String documentId) async {
    await _firestore
        .collection("users")
        .doc(userId)
        .collection('favoriteMusic')
        .doc(documentId)
        .delete();
  }

  void addToFavoritesFirestore(String documentId, String? title,
      String? description, String? imgUrl, String? songUrl) async {
    await _firestore
        .collection("users")
        .doc(userId) // Use the correct user ID here
        .collection('favoriteMusic')
        .doc(documentId)
        .set({
      'documentId': documentId,
      'title': title,
      'description': description,
      'imgUrl': imgUrl,
      'songUrl': songUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
