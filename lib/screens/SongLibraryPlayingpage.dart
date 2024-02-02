import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MusicPlayPage extends StatefulWidget {
  final String musicName;
  final String code;
  final String downloadUrl;
  final String documentId;

  MusicPlayPage(
      {required this.musicName,
      required this.code,
      required this.downloadUrl,
      required this.documentId});

  @override
  State<MusicPlayPage> createState() => _MusicPlayPageState();
}

class _MusicPlayPageState extends State<MusicPlayPage>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  bool _play = true;
  Duration _duration = const Duration();
  Duration _position = const Duration();
  final assetsAudioPlayer = AssetsAudioPlayer();
  late AnimationController _rotationController;
  bool musicLoaded = false;

  @override
  void initState() {
    super.initState();

    // Initialize the audio player and open the music file from the asset path
    assetsAudioPlayer.open(
      Audio.network(widget.downloadUrl),
      autoStart: true,
      showNotification: true,
    );

    // Initialize the animation controller
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Adjust the duration as needed
    );

    // Listen for audio playback completion to update the play/pause icon
    assetsAudioPlayer.playlistAudioFinished.listen((finishedEvent) {
      setState(() {
        _play = false;
      });
    });

    assetsAudioPlayer.current.listen((playing) {
      // Update duration when the audio is loaded and its duration is available
      setState(() {
        _duration = playing!.audio.duration;
        musicLoaded = true; // Music is loaded
      });
    });

    assetsAudioPlayer.currentPosition.listen((currentPosition) {
      // Update position when the audio position changes
      setState(() {
        _position = currentPosition;
      });
    });

    // Listen to changes in the play state and start/stop the animation
    assetsAudioPlayer.isPlaying.listen((isPlaying) {
      if (isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    assetsAudioPlayer.dispose();
    _rotationController.dispose(); // Dispose of the animation controller
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void skipForward() {
    setState(() {
      Duration newPosition = _position + const Duration(seconds: 10);
      if (newPosition > _duration) {
        newPosition = _duration;
      }
      assetsAudioPlayer.seek(newPosition);
    });
  }

  void skipBackward() {
    setState(() {
      Duration newPosition = _position - const Duration(seconds: 10);
      if (newPosition < Duration.zero) {
        newPosition = Duration.zero;
      }
      assetsAudioPlayer.seek(newPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF1a1b1f),
          ),
          child: Column(
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
                      color: Color(0xFF404040),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.42,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color:
                        widget.code.isNotEmpty ? null : const Color(0xFF30384b),
                    image: widget.code.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.code as String),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              const Color(0xFF1a1b1f).withOpacity(0.7),
                              BlendMode.multiply,
                            ),
                          )
                        : null,
                  ),
                  child: Center(
                    child: musicLoaded
                        ? RotationTransition(
                            turns: Tween(begin: 0.0, end: 1.0)
                                .animate(_rotationController),
                            child: CircleAvatar(
                              maxRadius: 80,
                              backgroundImage: widget.code is String &&
                                      widget.code.isNotEmpty
                                  ? NetworkImage(widget.code as String)
                                  : AssetImage('assets/logo.png')
                                      as ImageProvider<Object>?,
                              child: widget.code is String &&
                                      widget.code.isNotEmpty
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
                            highlightColor: Colors.lightBlue!,
                            child: const CircleAvatar(
                              maxRadius: 80,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28.0, right: 28.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Wrap with a Container to set a width constraint
                    Container(
                      width: 250, // Adjust the width as needed
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          widget.musicName,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
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
                              // Toggle the favorite state
                              setState(() {
                                isFavorite = !isFavorite;
                              });

                              // Add/remove the documentId to/from the "favoriteMusic" collection
                              if (isFavorite) {
                                // Add the documentId to the "favoriteMusic" collection
                                addToFavorites(widget.documentId);
                              } else {
                                // Remove the documentId from the "favoriteMusic" collection
                                removeFromFavorites(widget.documentId);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Slider(
                activeColor: const Color(0xFF27bc5c),
                inactiveColor: const Color(0xFF404040),
                value: _position.inSeconds.toDouble(),
                min: 0,
                max: _duration.inSeconds.toDouble(),
                onChanged: (double value) {
                  setState(() {
                    assetsAudioPlayer.seek(Duration(seconds: value.toInt()));
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDuration(_position),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFFFFFF)),
                    ),
                    Text(
                      formatDuration(_duration),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFFFFFF)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  Container(
                    width: 60, // Adjust the size as needed
                    height: 60, // Adjust the size as needed
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFFFFF), // Adjust the color as needed
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(
                          _play ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            _play = !_play;
                            if (_play) {
                              assetsAudioPlayer.play();
                            } else {
                              assetsAudioPlayer.pause();
                            }
                          });
                        },
                      ),
                    ),
                  ),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addToFavorites(String documentId) {
    // Assuming you have an instance of FirebaseFirestore
    FirebaseFirestore.instance.collection('favoriteMusic').add({
      'documentId': documentId,
      'timestamp': FieldValue.serverTimestamp(), // Optional: Store a timestamp
    }).then((value) {
      print('Document added to favorites: $value');
    }).catchError((error) {
      print('Failed to add document to favorites: $error');
    });
  }

  void removeFromFavorites(String documentId) {
    // Assuming you have an instance of FirebaseFirestore
    FirebaseFirestore.instance
        .collection('favoriteMusic')
        .where('documentId', isEqualTo: documentId)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete().then((_) {
          print('Document removed from favorites');
        }).catchError((error) {
          print('Failed to remove document from favorites: $error');
        });
      });
    }).catchError((error) {
      print('Error querying favorites: $error');
    });
  }
}
