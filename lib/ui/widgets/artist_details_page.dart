import 'package:flutter/material.dart';
import 'package:modern_art_app/data/artworks_dao.dart';
import 'package:modern_art_app/data/database.dart';
import 'package:modern_art_app/ui/widgets/item_list.dart';
import 'package:provider/provider.dart';

class ArtistDetailsPage extends StatelessWidget {
  const ArtistDetailsPage({Key key, this.artist}) : super(key: key);

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Artist details"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: artist.name,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(artist.fileName), fit: BoxFit.cover),
                  shape: BoxShape.circle),
            ),
          ),
          Text(artist.name, style: TextStyle(fontSize: 30)),
          Text("Description", style: TextStyle(fontSize: 25)),
          Text(artist.biography),
          Text("Artworks by ${artist.name}", style: TextStyle(fontSize: 25)),
          ListHorizontal(
              itemList:
                  Provider.of<ArtworksDao>(context).watchAllArtworkEntries),
        ],
      ),
    );
  }
}
