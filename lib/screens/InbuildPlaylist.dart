import 'package:flutter/material.dart';
import 'package:sync_music/screens/SongLibrary.dart';

class InbuildPlaylist extends StatefulWidget {
  final String? generatedCode;
  final bool isHostCreated;

  const InbuildPlaylist({
    Key? key,
    this.generatedCode,
    required this.isHostCreated,
  }) : super(key: key);

  @override
  State<InbuildPlaylist> createState() => _InbuildPlaylistState();
}

class _InbuildPlaylistState extends State<InbuildPlaylist> {
  void exitHost() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you want to exit the host?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pop(context); // Navigate back to the previous page
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
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
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      appBar: AppBar(
        backgroundColor: Color(0xFF221e3b),
        elevation: 0,
        title: Row(
          children: [
            SizedBox(
              width: 10,
              height: 5,
            ),
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
                Icons.music_note,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Library",
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
      body: Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 16),
                    child: Text(
                      "Trending Songs🔥",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 200,
                child: YourScreen(),
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 16),
                    child: Text(
                      "Famous Artist Playlist",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 200,
                child: YourScreen(),
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 16),
                    child: Text(
                      "Spritual(Hindi)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 200,
                child: YourScreen(),
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 16),
                    child: Text(
                      "Top Albums-Hindi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 200,
                child: YourScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
