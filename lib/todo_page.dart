import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:modern_art_app/data/artworks_dao.dart';
import 'package:modern_art_app/data/database.dart';
import 'package:modern_art_app/data/urls.dart';
import 'package:modern_art_app/painting_list.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'package:provider/provider.dart';

class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AppDatabase db = Provider.of<AppDatabase>(context);
    ArtworksDao dao = Provider.of<ArtworksDao>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Artworks"),
        actions: [
          IconButton(
              icon: Icon(Icons.list),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => MoorDbViewer(db)))),
          IconButton(
            icon: Icon(Icons.http),
            onPressed: () => getJson(dao, db),
          )
        ],
      ),
      body: StreamBuilder<List<Artwork>>(
        stream: dao.watchAllArtworkEntries,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final artworks = snapshot.data;
          return ListView.builder(
              itemCount: artworks.length,
              itemBuilder: (context, index) {
                Artwork artwork = artworks[index];
                return PaintingRow(
                  paintingName: "${artwork.id} ${artwork.title}",
                  path: "assets/paintings/${artwork.fileName}",
                );
              });
        },
      ),
    );
  }
}

void getJson(ArtworksDao dao, AppDatabase db) async {
  var jsonArtists = await http.get(gSheetUrlArtists);

  if (jsonArtists.statusCode == 200) {
    Map body = json.decode(jsonArtists.body);
    var artists = List<Map>.from(body["feed"]["entry"]);

    artists.forEach((item) {
      // convert map from Json to compatible Map for data class
      var itemMap = parseJsonMap(item);
      db.upsertArtist(Artist.fromJson(itemMap));
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
      dao.upsertArtwork(Artwork.fromJson(itemMap));
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
