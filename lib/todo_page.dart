import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:modern_art_app/data/artists_dao.dart';
import 'package:modern_art_app/data/artworks_dao.dart';
import 'package:modern_art_app/data/database.dart';
import 'package:modern_art_app/data/urls.dart';
import 'package:modern_art_app/ui/widgets/item_list.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'package:provider/provider.dart';

class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ArtistsDao artistsDao = Provider.of<ArtistsDao>(context);
    ArtworksDao artworksDao = Provider.of<ArtworksDao>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Artworks"),
        actions: [
          IconButton(
              icon: Icon(Icons.list),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      MoorDbViewer(Provider.of<AppDatabase>(context))))),
          IconButton(
            icon: Icon(Icons.http),
            onPressed: () => getJson(artworksDao, artistsDao),
          )
        ],
      ),
      body: ListVertical(itemList: artistsDao.watchAllArtistEntries),
    );
  }
}

Card _card(Artist artist) => Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.asset(artist.fileName),
          ListTile(
            title: Text(artist.name),
            subtitle: Text(artist.biography),
          ),
        ],
      ),
    );

void getJson(ArtworksDao artworksDao, ArtistsDao artistsDao) async {
  var jsonArtists = await http.get(gSheetUrlArtists);

  if (jsonArtists.statusCode == 200) {
    Map body = json.decode(jsonArtists.body);
    var artists = List<Map>.from(body["feed"]["entry"]);

    artists.forEach((item) {
      // convert map from Json to compatible Map for data class
      var itemMap = parseJsonMap(item);
      artistsDao.upsertArtist(Artist.fromJson(itemMap));
      print("added ${itemMap["name"]}");
    });
  } else {
    print("Error getting json: statusCode ${jsonArtists.statusCode}");
  }

  var jsonArtworks = await http.get(gSheetUrlArtworks);

  if (jsonArtworks.statusCode == 200) {
    Map body = json.decode(jsonArtworks.body);
    var artworks = List<Map>.from(body["feed"]["entry"]);

    artworks.forEach((item) {
      // convert map from Json to compatible Map for data class
      var itemMap = parseJsonMap(item);
      artworksDao.upsertArtwork(Artwork.fromJson(itemMap));
      print("added ${itemMap["title"]}");
    });
  } else {
    print("Error getting json: statusCode ${jsonArtworks.statusCode}");
  }
}

Map<String, dynamic> parseJsonMap(Map map) => Map<String, dynamic>.fromIterable(
      // filter keys, only interested in the ones that start with "gsx$"
      map.keys.where((k) => k.startsWith("gsx")),
      // remove "gsx$" from keys, to match with local data class column names
      key: (k) => k.replaceAll("gsx\$", ""),
      // get value for key, in the case of id parse it into int first
      value: (k) => k == "gsx\$id" ? int.parse(map[k]["\$t"]) : map[k]["\$t"],
    );