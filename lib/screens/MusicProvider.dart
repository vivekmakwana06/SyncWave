import 'package:flutter/material.dart';

class MusicProvider extends ChangeNotifier {
  late String musicName;
  late String code;
  late String downloadUrl;
  late String documentId;

  void setMusicInfo({
    required String musicName,
    required String code,
    required String downloadUrl,
    required String documentId,
  }) {
    this.musicName = musicName;
    this.code = code;
    this.downloadUrl = downloadUrl;
    this.documentId = documentId;
    notifyListeners();
  }
}


