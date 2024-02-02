import 'dart:async';
import 'dart:math';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:uuid/uuid.dart';

class MusicDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final String img;
  final String songUrl;

  const MusicDetailPage({
    Key? key,
    required this.title,
    required this.description,
    required this.color,
    required this.img,
    required this.songUrl,
  }) : super(key: key);

  @override
  _MusicDetailPageState createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
  int? result;
  bool isPlaying = true;
  bool syncMusic = false;
  Random random = Random();
  bool isFavorite = false;
  Duration duration = const Duration();
  Duration position = const Duration();
  late FirebaseFirestore firestore;
  late StreamSubscription<DocumentSnapshot> subscription;

  @override
  void initState() {
    super.initState();
    result = 100000 + random.nextInt(999999 - 100000);

    // Initialize Firestore
    firestore = FirebaseFirestore.instance;

    // Subscribe to changes in the sync document
    subscription = firestore
        .collection("sync")
        .doc(result.toString())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        // Update the state based on the changes in the sync document
        setState(() {
          position = Duration(milliseconds: event["currentPosition"]);
          isPlaying = event["isPlaying"];
        });
      }
    });

    playMusic(widget.songUrl);
  }

  void playMusic(String url) async {
    audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    audioPlayer.play(url);
    audioPlayer.onDurationChanged.listen((event) {
      setState(() {
        duration = event;
      });
    });

    audioPlayer.onAudioPositionChanged.listen((event) {
      setState(() {
        position = event;
        if (syncMusic) {
          updateSyncDocument();
        }
      });
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == AudioPlayerState.PLAYING) {
        isPlaying = true;
      } else {
        isPlaying = false;
      }
    });
  }

  void updateSyncDocument() {
    final docSync = firestore.collection("sync").doc(result.toString());
    docSync.update({
      'currentPosition': position.inMilliseconds,
      'isPlaying': isPlaying,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  seekMusic(int sec) {
    Duration newPosition = Duration(seconds: sec);
    audioPlayer.seek(newPosition);

    // Update sync document with new position and playing state
    if (syncMusic) {
      updateSyncDocument();
    }
  }

  void handlePlayPause() async {
    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.resume();
    }

    // Update sync document with new playing state
    if (syncMusic) {
      updateSyncDocument();
    }
  }

  // convert format time
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
    // Cancel the subscription when the widget is disposed
    subscription.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  void skipForward() {
    setState(() {
      Duration newPosition = position + const Duration(seconds: 10);
      if (newPosition > duration) {
        newPosition = duration;
      }
      audioPlayer.seek(newPosition);
    });
  }

  void skipBackward() {
    setState(() {
      Duration newPosition = position - const Duration(seconds: 10);
      if (newPosition < Duration.zero) {
        newPosition = Duration.zero;
      }
      audioPlayer.seek(newPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c091c),
      appBar: getAppBar(),
      body: getBody(),
    );
  }

  getAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Color.fromARGB(255, 236, 146, 3),
        ),
        onPressed: () {
          Navigator.pop(context); // Navigate back
        },
      ),
      titleSpacing: 0,
      backgroundColor: black,
      elevation: 0,
      actions: const [
        IconButton(
          icon: Icon(
            Icons.more_vert_sharp,
            color: white,
          ),
          onPressed: null,
        )
      ],
    );
  }

  Widget getBody() {
    var random = Random();
    final docSync =
        FirebaseFirestore.instance.collection("sync").doc(result.toString());
    result ??= 100000 + random.nextInt(999999 - 100000);

    // Inside MusicDetailPage
    if (result != null && syncMusic) {
      updateSyncDocument();
    }
    var size = MediaQuery.of(context).size;
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
                        color: widget.color,
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
                      image: DecorationImage(
                          image: NetworkImage(widget.img), fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(20)),
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
                  // const Icon(
                  //   Icons.my_library_add,
                  //   color: white,
                  // ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          flex: 2,
                          child: Text(
                            widget.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              color: white,
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
                              widget.description,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const Icon(
                  //   Icons.more_vert_sharp,
                  //   color: white,
                  // ),
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
                child: IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    // Toggle the favorite status
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                ),
              ),
            ),
          ),
          Slider.adaptive(
            activeColor: primary,
            value: position.inSeconds.clamp(0, duration.inSeconds).toDouble(),
            max: duration.inSeconds.toDouble(),
            min: 0.0,
            onChanged: (value) {
              setState(() {
                seekMusic(value.toInt());
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(position),
                  style: TextStyle(color: white.withOpacity(0.5)),
                ),
                Text(
                  formatTime(duration - position),
                  style: TextStyle(color: white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    skipBackward();
                  },
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                IconButton(
                    iconSize: 50,
                    icon: Container(
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: primary),
                      child: Center(
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 28,
                          color: white,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      if (isPlaying) {
                        await audioPlayer.pause();
                        setState(() {
                          isPlaying = false;
                        });
                      } else {
                        await audioPlayer.resume();
                        setState(() {
                          isPlaying = true;
                        });
                      }
                    }),
                IconButton(
                  onPressed: () {
                    skipForward();
                  },
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 2, color: Colors.white),
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.playlist_add,
                            color: Color.fromARGB(255, 236, 146, 3),
                            size: 30,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.download,
                            color: Color.fromARGB(255, 236, 146, 3),
                            size: 30,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              syncMusic = true;
              docSync.set({
                'musicName': widget.title,
                'artistName': widget.description,
                'songUrl': widget.songUrl,
                'imgUrl': widget.img
              });
              openDialog();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.sync,
                  color: primary,
                  size: 25,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "Sync Music",
                  style: TextStyle(color: primary, fontSize: 25),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future openDialog() => showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Music Sync",
              style: TextStyle(
                  color: Color.fromARGB(255, 236, 146, 3), fontSize: 24),
            ),
            content: Container(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromARGB(255, 236, 146, 3),
                        width: 4.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                    child: Text(
                      result.toString(),
                      style: TextStyle(color: Colors.green, fontSize: 50),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color.fromARGB(255, 236, 146, 3),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
