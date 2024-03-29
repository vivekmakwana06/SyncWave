import 'package:flutter/material.dart';

class MiniPlayer extends StatelessWidget {
  final String title;
  final String artist;
  final bool isPlaying;
  final VoidCallback onTap;

  const MiniPlayer({
    Key? key,
    required this.title,
    required this.artist,
    required this.isPlaying,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        color: Colors.black,
        child: Row(
          children: [
            SizedBox(width: 16),
            Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.white,
              size: 36,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    artist,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Add functionality to handle closing the mini player
              },
              icon: Icon(Icons.close, color: Colors.white),
            ),
            SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}


class MiniPlayerState extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void open() {
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
  }
}