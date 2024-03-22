import 'dart:async';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart' hide LoopMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicDetailPage extends StatefulWidget {
  final String? title;
  final String? description;
  final Color? color;
  final String? img;
  final String? songUrl;
  final bool? partyStatus;
  final String? result;
  final bool? syncMusicEnabled;

  final bool isCreatingHost;
  const MusicDetailPage({
    Key? key,
    this.title,
    this.result,
    this.partyStatus,
    this.description,
    this.color,
    this.img,
    this.songUrl,
    required this.isCreatingHost,
    this.syncMusicEnabled,
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

  Duration position = const Duration();
  late FirebaseFirestore firestore;
  late StreamSubscription<DocumentSnapshot> subscription;

  @override
  void initState() {
    super.initState();

    _userName = '';
    _loadUserName();
    assetsAudioPlayer = AssetsAudioPlayer();
    player = AudioPlayer();

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
        'currentPosition': 0, // Reset currentPosition when playing new song
        'isPlaying': true, // Start playing the new song
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
    super.dispose();
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
          color: Color(0xff6157ff),
        ),
        onPressed: () {
          Navigator.pop(context); // Navigate back
        },
      ),
      titleSpacing: 0,
      backgroundColor: Colors.black,
      elevation: 0,
      actions: const [
        IconButton(
          icon: Icon(
            Icons.more_vert_sharp,
            color: Colors.white,
          ),
          onPressed: null,
        )
      ],
    );
  }

  Widget getBody() {
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
                      image: DecorationImage(
                          image: NetworkImage(widget.img!), fit: BoxFit.cover),
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
                child: IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
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
              setState(() {
                seekMusic(Duration(seconds: value.toInt()));
                position = Duration(seconds: value.toInt());
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
          Padding(
            padding: const EdgeInsets.only(left: 90, right: 30),
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
                    iconSize: 80,
                    icon: Container(
                      decoration: const BoxDecoration(
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
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      handlePlayPause();
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
              ],
            ),
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
                children: [
                ],
              ),
            ),
          )
        ],
      ),
    );
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
