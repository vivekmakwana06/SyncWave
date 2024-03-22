import 'package:flutter/material.dart';

class MiniPlayer extends StatefulWidget {
  final String title;
  final String description;
  final String imgUrl;

  const MiniPlayer({
    Key? key,
    required this.title,
    required this.description,
    required this.imgUrl,
  }) : super(key: key);

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.black,
      child: Row(
        children: [
          Image.network(widget.imgUrl,
              width: 60, height: 60, fit: BoxFit.cover),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: TextStyle(color: Colors.white),
              ),
              Text(
                widget.description,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          Spacer(),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white),
            onPressed: () {
              setState(() {
                isPlaying = !isPlaying;
              });
              // Implement play/pause functionality here
            },
          ),
          IconButton(
            icon: Icon(Icons.skip_next, color: Colors.white),
            onPressed: () {
              // Implement skip to next track functionality here
            },
          ),
        ],
      ),
    );
  }
}
