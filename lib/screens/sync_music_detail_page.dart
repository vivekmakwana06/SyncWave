import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:shimmer/shimmer.dart';
import 'dart:async';

import 'package:sync_music/theme/colors.dart';

class SyncMusicDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final String img;
  final String songUrl;
  final Duration currentPosition;

  final Function(String) onSongUrlChanged;

  const SyncMusicDetailPage({ 
    Key? key,
    required this.title,
    required this.description,
    required this.color,
    required this.img,
    required this.songUrl,
    required this.currentPosition,
    required this.onSongUrlChanged,
  }) : super(key: key);

  @override
  _SyncMusicDetailPageState createState() => _SyncMusicDetailPageState();
}

class _SyncMusicDetailPageState extends State<SyncMusicDetailPage>
    with SingleTickerProviderStateMixin {
  AudioPlayer audioPlayer = AudioPlayer();

  AudioPlayerState audioPlayerState = AudioPlayerState.PAUSED;
  bool isPlaying = true;
  bool syncMusic = false;
  late Timer _timer;
  String title = "";
  int audioState = 1;
  Duration pos = const Duration();
  Duration duration = const Duration(seconds: 594);
  Duration position = const Duration();
  int timeDifference = 0;
  late Duration initialPosition;
  late AnimationController _rotationController;
  // bool musicLoaded = false;
  late bool musicLoaded;
  late FirebaseFirestore firestore;
  late StreamSubscription<DocumentSnapshot> subscription;

  @override
  void initState() {
    super.initState();
    musicLoaded = false;

    initialPosition = widget.currentPosition;
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Adjust the duration as needed
    );
    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      audioPlayerState = s;
    });

    // Initialize Firestore
    firestore = FirebaseFirestore.instance;

    subscription = firestore
        .collection("sync")
        .doc(widget.title)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        setState(() {
          position = Duration(milliseconds: event["currentPosition"]);
          isPlaying = event["isPlaying"];
          // Call the callback function to update the song URL
        });
      }
    });

    audioPlayer.onDurationChanged.listen((event) {
      setState(() {
        duration = event;
        musicLoaded = true;
      });
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == AudioPlayerState.PLAYING) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    playMusic(widget.songUrl);
  }

  void playMusic(String url) async {
    // Stop the current song before playing the new song
    audioPlayer.stop();

    // Set the initial position of the audio player
    audioPlayer.seek(widget.currentPosition);

    // Start playing the new song
    audioPlayer.play(url);

    // Calculate the starting point for syncing playback
    int syncStartTime = widget.currentPosition.inMilliseconds;
    syncStartTime += DateTime.now().millisecond;
    timeDifference = syncStartTime - DateTime.now().millisecondsSinceEpoch;

    // Apply time difference to sync device's seekbar position
    syncStartTime -= timeDifference;
    audioPlayer.seek(Duration(milliseconds: syncStartTime));

    _timer = Timer.periodic(const Duration(microseconds: 1), (timer) {
      setState(() {
        title = "${DateTime.now().millisecond}";
      });
    });
    audioPlayer.setReleaseMode(ReleaseMode.STOP);

    audioPlayer.onAudioPositionChanged.listen((event) {
      setState(() {
        position = widget.currentPosition;
      });
    });
  }

  // void updateSyncDocument() {
  //   final docSync = firestore.collection("sync").doc(widget.title);

  //   // Apply time difference to adjust the position sent to Firestore
  //   final adjustedPosition = position.inMilliseconds + timeDifference;

  //   docSync.update({
  //     'currentPosition': adjustedPosition,
  //     'isPlaying': isPlaying,
  //   });

  //   // Update the playback position of the music
  //   audioPlayer.seek(Duration(milliseconds: adjustedPosition));
  // }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer
    subscription.cancel();
    audioPlayer.release();
    audioPlayer.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    if (audioState == 1 && audioPlayerState == AudioPlayerState.PLAYING) {
      int timer = 0;
      try {
        timer = int.parse(widget.title);
      } catch (e) {
        print('Error parsing title: $e');
      }

      Duration currentPosition =
          Duration(milliseconds: timer + widget.currentPosition.inMilliseconds);
      audioPlayer.seek(currentPosition);
      _timer.cancel();
      audioState = 0;
    }

    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      floatingActionButton: Container(
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
            Navigator.pop(context); // Navigate back
          },
          backgroundColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Text(
              'Leave Host',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 245, 245, 245),
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
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
    var size = MediaQuery.of(context).size;
    print('First Position: ${widget.currentPosition}');
    if (!widget.description.isEmpty) {
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
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: widget.color,
                          blurRadius: 50,
                          spreadRadius: 5,
                          offset: const Offset(-10, 40),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                  child: Container(
                    width: size.width - 60,
                    height: size.width - 60,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.img),
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
                              widget.title,
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
                                widget.description,
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
              height: 10,
            ),
            Slider(
              activeColor: primary,
              value: position.inSeconds.toDouble(),
              max: duration.inSeconds.toDouble(),
              min: 0.0,
              onChanged: (double value) {},
            ),
            const SizedBox(height: 20),
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
          ],
        ),
      );
    } else {
      // Document does not exist, return a blank music player
      return SingleChildScrollView(
        child: Column(
          children: [
            // Default blank music player content
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.music_note,
                  size: 100,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Unknown Title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Unknown Artist',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Slider(
              activeColor: Color(0xff6157ff),
              value: 0,
              max: 100,
              min: 0,
              onChanged: (double value) {},
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0:00',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                Text(
                  '0:00',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
