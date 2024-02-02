import 'package:flutter/material.dart';

class DownloadedSong extends StatefulWidget {
  const DownloadedSong({super.key});

  @override
  State<DownloadedSong> createState() => _DownloadedSongState();
}

class _DownloadedSongState extends State<DownloadedSong> {
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
            color: Color.fromARGB(255, 236, 146, 3),
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        titleSpacing: 0, // Set titleSpacing to 0
        title: Row(
          children: [
            // SizedBox(
            //   width: 10,
            //   height: 5,
            // ),
            Icon(
              Icons.download,
              color: Color.fromARGB(255, 236, 146, 3),
              size: 34,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Download Song',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Offline Play Your Download Song...',
                  style: TextStyle(
                    fontWeight: FontWeight.w200,
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      body: Container(),
    );
  }
}
