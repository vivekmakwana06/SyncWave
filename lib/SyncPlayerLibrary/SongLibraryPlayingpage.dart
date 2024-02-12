import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MusicPlayPage extends StatefulWidget {
  final String? musicName;
  final String? code;
  final String? downloadUrl;
  final String? documentId;
  final int? playerId;
  final String? userEmail;
  final String? generatedCode;

  MusicPlayPage({
    this.musicName,
    this.code,
    this.downloadUrl,
    this.documentId,
    this.playerId = 2,
    this.userEmail,
    this.generatedCode,
  });

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
  bool isDownloaded = false;
  bool isPlaying = true;
  bool syncMusic = false;
  late FirebaseFirestore firestore;
  late StreamSubscription<DocumentSnapshot> subscription;

  int? result;

  @override
  void initState() {
    super.initState();

    firestore = FirebaseFirestore.instance;

    // Listen for changes in the sync document
    subscription = firestore
        .collection("SyncInbuildPlaylist")
        .doc(widget.documentId)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        setState(() {
          _position = Duration(milliseconds: event["currentPosition"]);
          isPlaying = event["isPlaying"];
        });

        // Seek to the updated position
        assetsAudioPlayer.seek(_position);

        // Handle play/pause state
        if (isPlaying) {
          assetsAudioPlayer.play();
        } else {
          assetsAudioPlayer.pause();
        }
      }
    });

    // Initialize the audio player and open the music file from the asset path
    assetsAudioPlayer.open(
      Audio.network(widget.downloadUrl!),
      autoStart: true,
      showNotification: true, // Ensure showNotification is set to true
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

    // Listen to changes in the play state and start/stop the
    // animation
    assetsAudioPlayer.isPlaying.listen((isPlaying) {
      if (isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
    checkDownloadStatus();
    playMusic(widget.downloadUrl!);
  }

  void playMusic(String url) {
    final audio = Audio.network(
      url,
      metas: Metas(
        title: widget.musicName,
        // artist: widget.hostCode ??
        //     '', // Provide a default value if hostCode is null
        image: MetasImage.asset('assets/logo.png'),
      ),
    );

    assetsAudioPlayer.open(
      audio,
      showNotification: true,
      playInBackground: PlayInBackground.enabled,
      // loopMode: playerLoopMode,
      autoStart: true,
    );

    assetsAudioPlayer.currentPosition.listen((event) {
      setState(() {
        _position = event;
        if (syncMusic) {
          // Update sync document when music is playing
          updateSyncDocument();
        }
      });
    });

    assetsAudioPlayer.current.listen((event) {
      setState(() {
        _duration = event!.audio.duration;
      });
    });

    assetsAudioPlayer.isPlaying.listen((event) {
      setState(() {
        isPlaying = event;
      });
    });
  }

  void updateSyncDocument() {
    final docSync =
        firestore.collection("SyncInbuildPlaylist").doc(result.toString());
    docSync.update({
      'currentPosition': _position.inMilliseconds,
      'isPlaying': isPlaying,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> checkDownloadStatus() async {
    // Your logic to check if the song is downloaded goes here
    // You can check if the song is downloaded by checking if its details are present in the local database
    final database = await openDatabase(
      path.join(await getDatabasesPath(), 'downloads.db'),
      version: 1,
    );
    final List<Map<String, dynamic>> downloads = await database.query(
      'downloads',
      where: 'documentId = ?',
      whereArgs: [widget.documentId],
    );
    if (downloads.isNotEmpty) {
      // Song is downloaded
      setState(() {
        isDownloaded = true;
      });
    }
  }

  @override
  void dispose() {
    assetsAudioPlayer.dispose();
    _rotationController.dispose();
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

  Future<void> addToDownloads() async {
    final Dio dio = Dio();
    final String downloadPath =
        await getApplicationDocumentsDirectory().then((value) => value.path);

    try {
      final Response response = await dio.download(
        widget.downloadUrl!,
        '$downloadPath/${widget.musicName}.mp3', // Adjust the file extension based on your audio format
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Handle download progress if needed
          }
        },
      );

      if (response.statusCode == 200) {
        // Download successful, now save details to the database
        await saveToDatabase('$downloadPath/${widget.musicName}.mp3');
        setState(() {
          isDownloaded = true; // Update the state variable
        });
        print('Download successful');
      } else {
        // Handle download error
        print('Download error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle download error
      print('Download error: $error');
    }
  }

  Future<void> saveToDatabase(String localFilePath) async {
    final database = await openDatabase(
      path.join(await getDatabasesPath(), 'downloads.db'),
      version: 1,
    );

    try {
      await database.transaction((txn) async {
        await txn.execute(
          'CREATE TABLE IF NOT EXISTS downloads(id INTEGER PRIMARY KEY, musicName TEXT, code TEXT, downloadUrl TEXT, documentId TEXT, localFilePath TEXT)',
        );

        await txn.rawInsert(
          'INSERT OR REPLACE INTO downloads (musicName, code, downloadUrl, documentId, localFilePath) VALUES (?, ?, ?, ?, ?)',
          [
            widget.musicName,
            widget.code,
            widget.downloadUrl,
            widget.documentId,
            localFilePath,
          ],
        );
      });

      // Display a SnackBar to show the download success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Song Downloaded successfully....',
            style: GoogleFonts.kanit(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 236, 146, 3),
              fontSize: 20,
            ),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      // Handle database error
      print('Database error: $error');
    }
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
                    color: widget.code!.isNotEmpty
                        ? null
                        : const Color(0xFF30384b),
                    image: widget.code!.isNotEmpty
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
                                      widget.code!.isNotEmpty
                                  ? NetworkImage(widget.code as String)
                                  : AssetImage('assets/logo.png')
                                      as ImageProvider<Object>?,
                              child: widget.code is String &&
                                      widget.code!.isNotEmpty
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
                height: 10,
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
                          widget.musicName ?? '',
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
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
              Padding(
                padding: const EdgeInsets.only(left: 260),
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
                          addToFavorites(widget.documentId!);
                        } else {
                          // Remove the documentId from the "favoriteMusic" collection
                          removeFromFavorites(widget.documentId!);
                        }
                      },
                    ),
                  ),
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
                              isDownloaded
                                  ? Icons.done
                                  : Icons
                                      .download, // Use isDownloaded to determine the icon
                              color: Color.fromARGB(255, 236, 146, 3),
                              size: 30,
                            ),
                            onPressed: () {
                              if (isDownloaded) {
                                // Song is already downloaded, show a message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Song is already downloaded',
                                      style: TextStyle(
                                        fontSize: 25,
                                        color: Color.fromARGB(255, 236, 146, 3),
                                      ),
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                // Song is not downloaded, download it
                                addToDownloads();
                              }
                            },
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
