import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import 'package:sync_music/theme/colors.dart';

class SyncMusicDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final String img;
  final String songUrl;
  final Duration currentPosition;
  final Function(String) onSongUrlChanged; // Add a callback function

  const SyncMusicDetailPage({
    Key? key,
    required this.title,
    required this.description,
    required this.color,
    required this.img,
    required this.songUrl,
    required this.currentPosition,
    required this.onSongUrlChanged, // Pass the callback function as a parameter
  }) : super(key: key);

  @override
  _SyncMusicDetailPageState createState() => _SyncMusicDetailPageState();
}

class _SyncMusicDetailPageState extends State<SyncMusicDetailPage> {
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

  late FirebaseFirestore firestore;
  late StreamSubscription<DocumentSnapshot> subscription;

  @override
  void initState() {
    super.initState();
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
          widget.onSongUrlChanged(event["songUrl"]);
        });

        // Handle play/pause state
        if (isPlaying) {
          audioPlayer.resume();
        } else {
          audioPlayer.pause();
        }

        // Check if the song URL has changed
        String newSongUrl = event["songUrl"];
        if (newSongUrl != widget.songUrl) {
          // Stop the current song and play the new song
          playMusic(newSongUrl);
        }
      }
    });

    void updateSyncDocument() {
      final docSync = firestore.collection("sync").doc(widget.title);

      // Apply time difference to adjust the position sent to Firestore
      final adjustedPosition = position.inMilliseconds + timeDifference;

      docSync.update({
        'currentPosition': adjustedPosition,
        'isPlaying': isPlaying,
      });
    }

    playMusic(widget.songUrl);
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer
    subscription.cancel(); // Cancel the Firestore subscription
    audioPlayer.release();
    audioPlayer.dispose();
    super.dispose();
  }

  void playMusic(String url) async {
    // Stop the current song before playing the new song
    audioPlayer.stop();

    audioPlayer.play(url);
    pos = widget.currentPosition;

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

    // Update the song URL on the synced device
    updateSongUrlOnSyncedDevice(url);
  }

  void updateSongUrlOnSyncedDevice(String newSongUrl) {
    final docSync = firestore.collection("sync").doc(widget.title);
    docSync.update({
      'songUrl': newSongUrl,
    });
  }

  void updateSyncDocument() {
    final docSync = firestore.collection("sync").doc(widget.title);

    // Apply time difference to adjust the position sent to Firestore
    final adjustedPosition = position.inMilliseconds + timeDifference;

    docSync.update({
      'currentPosition': adjustedPosition,
      'isPlaying': isPlaying,
    });
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
      int timer = int.parse(title);
      timer = timer + 2600;
      Duration currentPosition = Duration(milliseconds: timer);
      currentPosition += widget.currentPosition;
      audioPlayer.seek(currentPosition);
      _timer.cancel();
      audioState = 0;
    }

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
    var size = MediaQuery.of(context).size;
    if (!widget.description.isEmpty) {
      // Document exists, return the music player
      return SingleChildScrollView(
        child: Column(
          children: [
            // Existing body content
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
              activeColor: Color(0xff6157ff),
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
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  Text(
                    formatTime(duration - position),
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
