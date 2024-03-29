import 'dart:async';
import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:sync_music/theme/colors.dart';

class MusicPlayPage extends StatefulWidget {
  final String? musicName;
  final String? image;
  final String? downloadUrl;
  final String? documentId;
  final int? playerId;
  final String? userEmail;
  final String? generatedCode;

  MusicPlayPage({
    this.musicName,
    this.image,
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
  double _downloadProgress = 0.0;

  int? generatedCode;

  @override
  void initState() {
    super.initState();

    firestore = FirebaseFirestore.instance;

    subscription = firestore
        .collection("SyncInbuildPlaylist")
        .doc(widget.generatedCode)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        setState(() {
          // Check if the field "currentPosition" exists in the document snapshot
          if (event.data()!.containsKey('currentPosition')) {
            _position = Duration(milliseconds: event['currentPosition'] ?? 0);
          }
          isPlaying = event['isPlaying'] ?? true;
        });

        // Seek to the updated position if available
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
      duration: const Duration(seconds: 50), // Adjust the duration as needed
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
    playMusic(widget.downloadUrl!, widget.musicName!, widget.image!);
  }

  void playMusic(String url, String? musicName, String? image) {
    if (url.isNotEmpty &&
        musicName != null &&
        musicName.isNotEmpty &&
        image != null &&
        image.isNotEmpty) {
      Audio audio;
      if (isDownloaded) {
        audio = Audio.file(widget.downloadUrl!,
            metas: Metas(
              title: musicName,
              image: MetasImage.asset('assets/logo.png'),
            ));
      } else {
        audio = Audio.network(widget.downloadUrl!,
            metas: Metas(
              title: musicName,
              image: MetasImage.asset('assets/logo.png'),
            ));
      }

      assetsAudioPlayer.open(
        audio,
        showNotification: true,
        playInBackground: PlayInBackground.enabled,
        autoStart: true,
      );

      assetsAudioPlayer.currentPosition.listen((event) {
        setState(() {
          _position = event;
          if (syncMusic) {
            updateSyncDocument(musicName, url, image);
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
    } else {
      // Display error message to the user indicating that all fields are required.
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("URL, image, and song name are required."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void updateSyncDocument(String url, String? musicName, String? image) {
    if (widget.generatedCode != null && widget.generatedCode!.isNotEmpty) {
      final docSync =
          firestore.collection("SyncInbuildPlaylist").doc(widget.generatedCode);
      docSync.update({
        'currentPosition': _position.inMilliseconds,
        'isPlaying': isPlaying,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      print("Error: Generated code is null or empty.");
    }
  }

  Widget _buildProgressBar() {
    return Container(
      width: 200, // Adjust the width as needed
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 236, 146, 3),
            ),
          ),
          SizedBox(
              height: 5), // Add spacing between progress bar and percentage
          Text(
            '${(_downloadProgress * 100).toStringAsFixed(0)}%', // Convert progress to percentage
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
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
    // Request storage permission
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      final Dio dio = Dio();
      final String downloadPath =
          await getApplicationDocumentsDirectory().then((value) => value.path);

      try {
        final Response response = await dio.download(
          widget.downloadUrl!,
          '$downloadPath/${widget.musicName}.mp3',
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _downloadProgress = (received / total);
              });
            }
          },
        );

        if (response.statusCode == 200) {
          // Download successful, now save details to the database
          await saveToDatabase('$downloadPath/${widget.musicName}.mp3');
          setState(() {
            isDownloaded = true;
          });

          // Save to device's music library
          final filePath = '$downloadPath/${widget.musicName}.mp3';
          if (Platform.isAndroid) {
            // On Android, add the file to the media library
            await AudioService.addQueueItem(MediaItem(
              id: filePath,
              album: widget.musicName,
              title: widget.musicName!,
              artist: "Unknown Artist",
              genre: "Unknown Genre",
              extras: {
                "uri": filePath,
              },
            ));
          } else if (Platform.isIOS) {
            // On iOS, you may need to use another method to add the file to the library
            // Please refer to iOS specific documentation for this.
          }

          print('Download successful');
        } else {
          // Handle download error
          print('Download error: ${response.statusCode}');
        }
      } catch (error) {
        // Handle download error
        print('Download error: $error');
      }
    } else {
      // Handle the scenario where permission is denied
      print('Storage permission denied');
    }
    await downloadSong(widget.downloadUrl!, widget.musicName!);
  }

  Future<void> downloadSong(String downloadUrl, String musicName) async {
    final directory = await getExternalStorageDirectory();
    final savePath = directory!.path + '/$musicName.mp3';

    final taskId = await FlutterDownloader.enqueue(
      url: downloadUrl,
      savedDir: directory.path,
      fileName: '$musicName.mp3',
      showNotification: true,
      openFileFromNotification: true,
    );

    FlutterDownloader.registerCallback((id, status, progress) async {
      if (status == DownloadTaskStatus.complete) {
        // Once the download is complete, add the song to the media store
        addSongToMediaStore(savePath, musicName);
        // Set state to indicate that download is completed
        setState(() {
          isDownloaded = true;
        });
      }
    });
  }

  Future<void> addSongToMediaStore(String filePath, String musicName) async {
    // Use platform-specific code to scan the file and add it to the media store
    if (Platform.isAndroid) {
      // For Android, you can use the MediaScanner to scan the file
      await Process.run('am', [
        'broadcast',
        '-a',
        'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
        '-d',
        'file://$filePath'
      ]);
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
            widget.image,
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 236, 146, 3),
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
    final docSync = FirebaseFirestore.instance
        .collection("SyncInbuildPlaylist")
        .doc(generatedCode.toString());
    // var random = Random();
    // generatedCode ??= 100000 + random.nextInt(999999 - 100000);
    // Inside MusicDetailPage
    if (generatedCode != null && syncMusic) {
      updateSyncDocument(widget.musicName!, widget.downloadUrl!, widget.image!);
    }
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF221e3b),
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
                    color: widget.image!.isNotEmpty
                        ? null
                        : const Color(0xFF30384b),
                    image: widget.image!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.image as String),
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
                              backgroundImage: widget.image is String &&
                                      widget.image!.isNotEmpty
                                  ? NetworkImage(widget.image as String)
                                  : AssetImage('assets/logo.png')
                                      as ImageProvider<Object>?,
                              child: widget.image is String &&
                                      widget.image!.isNotEmpty
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
                    // Wrap with a Container to

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
                  height: 45,
                  width: 55,
                  child: CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 52, 50, 50),
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 30,
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
                activeColor: const Color(0xffee49fd),
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
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
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
                height: 15,
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
                    width: 70, // Adjust the size as needed
                    height: 70, // Adjust the size as needed
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment(-0.95, 0.0),
                        end: Alignment(1.0, 0.0),
                        colors: [Color(0xff6157ff), Color(0xffee49fd)],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          gradient: LinearGradient(
                            begin: Alignment(-0.95, 0.0),
                            end: Alignment(1.0, 0.0),
                            colors: [Color(0xff6157ff), Color(0xffee49fd)],
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _play ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 37,
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
                    padding: const EdgeInsets.only(left: 10, right: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        // border: Border.all(width: 2, color: Colors.white),
                        color: Color.fromARGB(255, 52, 50, 50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            child: IconButton(
                              icon: Icon(
                                Icons.playlist_add,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isDownloaded
                                  ? Icons.done
                                  : Icons
                                      .download, // Use isDownloaded to determine the icon
                              color: Colors.white,
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
                                        fontSize: 2,
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
              // GestureDetector(
              //   onTap: () async {
              //     syncMusic = true;
              //     await docSync.set({
              //       'musicName': widget.musicName,
              //       'downloadUrl': widget.downloadUrl,
              //       'documentId': widget.documentId,
              //       'image': widget.image,
              //     });

              //     await openDialog();
              //     // Navigate to SyncMusicPlayer1 with the generated code
              //     // Navigator.push(
              //     //   context,
              //     //   MaterialPageRoute(
              //     //     builder: (context) => SyncMusicPlayer1(
              //     //         documentId: generatedCode.toString()),
              //     //   ),
              //     // );
              //   },
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: const [
              //       Icon(
              //         Icons.sync,
              //         color: primary,
              //         size: 25,
              //       ),
              //       SizedBox(
              //         width: 10,
              //       ),
              //       Text(
              //         "Sync Music",
              //         style: TextStyle(color: primary, fontSize: 25),
              //       ),
              //     ],
              //   ),
              // ),
              if (_downloadProgress > 0 && _downloadProgress < 1.0)
                _buildProgressBar(),
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
