// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const Set<Song> songs = {
  // Filenames with whitespace break package:audioplayers on iOS
  // (as of February 2022), so we use no whitespace.
  // Song('Mr_Smith-Azul.mp3', 'Azul', artist: 'Mr Smith'),
  // Song('Mr_Smith-Sonorus.mp3', 'Sonorus', artist: 'Mr Smith'),
  // Song('Mr_Smith-Sunday_Solitude.mp3', 'SundaySolitude', artist: 'Mr Smith'),
  Song('One Man Symphony - Undauntable (Free) - 01 Hell On Earth.mp3',
      'HellOnEarth',
      artist: 'One Man Symphony'),
  Song(
      "One Man Symphony - Undauntable (Free) - 02 The One Who Doesn't Back Down.mp3",
      'TheOneWhoDoesntBackDown',
      artist: 'One Man Symphony'),
  Song("One Man Symphony - Undauntable (Free) - 03 Undauntable.mp3",
      'Undauntable',
      artist: 'One Man Symphony'),
};

class Song {
  final String filename;

  final String name;

  final String? artist;

  const Song(this.filename, this.name, {this.artist});

  @override
  String toString() => 'Song<$filename>';
}
