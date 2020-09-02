import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:modern_art_app/data/database.dart';
import 'package:photo_view/photo_view.dart';

class ArtworkDetailsPage extends StatelessWidget {
  final Artwork artwork;

  const ArtworkDetailsPage({Key key, this.artwork}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Artwork details"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ItemZoomPage(
                            fileName: artwork.fileName,
                            heroTag: artwork.title,
                          ))),
              child: Hero(
                tag: artwork.title,
                child: Container(
                  height: size.height * 0.6,
                  width: size.width,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(artwork.fileName),
                          fit: BoxFit.fitHeight)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 12.0, 4.0, 0.0),
              child: Text(artwork.title, style: TextStyle(fontSize: 30)),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                  "${artwork.artist}" +
                      (artwork.year != "" ? ", ${artwork.year}" : ""),
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 12.0, 4.0, 0.0),
              child: Text("Description", style: TextStyle(fontSize: 20)),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(lorem(
                  paragraphs: 3, words: 250 - math.Random().nextInt(100))),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemZoomPage extends StatelessWidget {
  final String fileName;
  final String heroTag;

  const ItemZoomPage({Key key, @required this.fileName, this.heroTag})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
      ),
      child: PhotoView(
        imageProvider: AssetImage(fileName),
        heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
      ),
    );
  }
}