import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class SyncMusicDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final String img;
  final String songUrl;
  final Duration currentPosition;

  const SyncMusicDetailPage({
    Key? key,
    required this.title,
    required this.description,
    required this.color,
    required this.img,
    required this.songUrl,
    required this.currentPosition,
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
        });

        // Seek to the updated position
        audioPlayer.seek(position);

        // Handle play/pause state
        if (isPlaying) {
          audioPlayer.resume();
        } else {
          audioPlayer.pause();
        }
      }
    });

    playMusic(widget.songUrl);
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    subscription.cancel();
    audioPlayer.release();
    audioPlayer.dispose();
    super.dispose();
  }

  void playMusic(String url) async {
    audioPlayer.play(url);
    pos = widget.currentPosition;

    // Calculate the starting point for syncing playback
    int syncStartTime = widget.currentPosition.inMilliseconds;
    syncStartTime += DateTime.now().millisecond;
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
  }

  void updateSyncDocument() {
    final docSync = firestore.collection("sync").doc(widget.title);
    docSync.update({
      'currentPosition': position.inMilliseconds,
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
            activeColor: Colors.blue,
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
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: Colors.white.withOpacity(0.8),
                    size: 25,
                  ),
                  onPressed: null,
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: Colors.white.withOpacity(0.8),
                    size: 25,
                  ),
                  onPressed: null,
                ),
                IconButton(
                  iconSize: 50,
                  icon: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: Center(
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    // Handle play/pause logic here
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: Colors.white.withOpacity(0.8),
                    size: 25,
                  ),
                  onPressed: null,
                ),
                IconButton(
                  icon: Icon(
                    Icons.cached,
                    color: Colors.white.withOpacity(0.8),
                    size: 25,
                  ),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
