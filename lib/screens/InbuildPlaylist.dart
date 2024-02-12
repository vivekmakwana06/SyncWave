import 'package:flutter/material.dart';
import 'package:sync_music/SyncPlayerLibrary/SongLibrary.dart';

class InbuildPlaylist extends StatefulWidget {
  final String? userEmail;
  final String? generatedCode;
  final bool isHostCreated;

  const InbuildPlaylist({
    Key? key,
    this.userEmail,
    this.generatedCode,
    required this.isHostCreated,
  }) : super(key: key);

  @override
  State<InbuildPlaylist> createState() => _InbuildPlaylistState();
}

class _InbuildPlaylistState extends State<InbuildPlaylist> {
  void exitHost() {
    Navigator.pop(context); // Navigate back to the previous page
  }

  @override
  void initState() {
    super.initState();
    if (widget.isHostCreated) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Successfully created host, let's play song and Enjoy Party...",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                  fontWeight: FontWeight.w600),
            ),
            duration: Duration(seconds: 5), // Adjust the duration as needed
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1b1f),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1b1f),
        elevation: 0,
        title: const Row(
          children: [
            SizedBox(
              width: 10,
              height: 5,
            ),
            Icon(
              Icons.library_books,
              color: Color.fromARGB(255, 236, 146, 3),
              size: 30,
            ),
            SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Library",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Let's listen,sync song and enjoy party...",
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
      floatingActionButton: widget.isHostCreated
          ? FloatingActionButton(
              onPressed: () {
                exitHost();
              },
              backgroundColor: Color.fromARGB(255, 236, 146, 3),
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  'Exist Host..',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 24, 24, 24),
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 650,
              color: const Color(0xFF1a1b1f),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 24, top: 16),
                        child: Text(
                          "Enjoy The Trending Songs🔥",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    flex: 10,
                    child: YourScreen(
                      userEmail: widget.userEmail ?? '',
                      generatedCode: widget.generatedCode ?? '',
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 24, top: 16),
                        child: Text(
                          "Famous Artist Playlist💖",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    flex: 10,
                    child: YourScreen(
                      userEmail: widget.userEmail ?? '',
                      generatedCode: widget.generatedCode ?? '',
                    ),
                  ),
                  Expanded(
                    flex: 14,
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFF1a1b1f),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
