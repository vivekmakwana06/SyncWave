
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sync_music/screens/SongLibraryPlayingpage.dart';

class DownloadedSong extends StatefulWidget {
  const DownloadedSong({Key? key}) : super(key: key);

  @override
  State<DownloadedSong> createState() => _DownloadedSongState();
}

class _DownloadedSongState extends State<DownloadedSong> {
  List<Map<String, dynamic>> downloadedSongs = [];

  @override
  void initState() {
    super.initState();
    getDownloadedSongs();
  }

  Future<void> getDownloadedSongs() async {
    final database = await openDatabase(
      path.join(await getDatabasesPath(), 'downloads.db'),
      version: 1,
    );

    final List<Map<String, dynamic>> songs = await database.query('downloads');
    setState(() {
      downloadedSongs = songs;
    });
  }

  // Function to delete a downloaded song
  Future<void> deleteDownloadedSong(String documentId, String musicName) async {
    // Show a confirmation dialog before deleting the song
    bool deleteConfirmed = await showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return AlertDialog(
          title: Text(
            'Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you want to sure to delete .... $musicName?',
            style: TextStyle(fontWeight: FontWeight.w300, fontSize: 17),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(buildContext).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(buildContext).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    // If the user confirms deletion, proceed with deleting the song
    if (deleteConfirmed == true) {
      final database = await openDatabase(
        path.join(await getDatabasesPath(), 'downloads.db'),
        version: 1,
      );

      await database.delete(
        'downloads',
        where: 'documentId = ?',
        whereArgs: [documentId],
      );

      // Refresh the song list after deletion
      getDownloadedSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1b1f),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1b1f),
        elevation: 0,
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
                Icons.download,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SizedBox(
                //   height: 10,
                // ),
                Text(
                  'Downloaded Songs',
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
      body: Container(
        padding: EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: downloadedSongs.length,
          itemBuilder: (context, index) {
            final song = downloadedSongs[index];
            return Card(
              elevation: 4,
              color: Color(0xFF2C2C2C), // You can customize the card color
              child: ListTile(
                leading: Icon(
                  Icons.music_note,
                  size: 35,
                  color: Color.fromARGB(255, 236, 146, 3),
                ),
                title: Text(
                  song['musicName'] ?? '',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Delete the downloaded song when the delete icon is clicked
                    deleteDownloadedSong(song['documentId'], song['musicName']);
                  },
                ),
                onTap: () {
                  // Add code to play the downloaded song
                  playDownloadedSong(song);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Function to play the downloaded song
  void playDownloadedSong(Map<String, dynamic> song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayPage(
          musicName: song['musicName'],
          image: song['code'],
          downloadUrl: song[
              'localFilePath'], // Pass local file path for offline playback
          documentId: song['documentId'],
        ),
      ),
    );
  }
}
