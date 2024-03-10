// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:temporal_global_citizen/player_progress/player_progress.dart';
import 'package:temporal_global_citizen/project_view_component.dart';
import 'package:temporal_global_citizen/settings/settings.dart';
import 'package:temporal_global_citizen/style/palette.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/level_state.dart';
import '../level_selection/levels.dart';

import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart' as flame;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jenny/jenny.dart';
import 'package:flame/sprite.dart';

import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;

import 'package:webview_flutter/webview_flutter.dart';
import 'package:temporal_global_citizen/game_internals/data_fetcher.dart';

/// This widget defines the game UI itself, without things like the settings
/// button or the back button.

class GameWidget extends StatefulWidget {
  const GameWidget({Key? key}) : super(key: key);

  @override
  _GameWidgetState createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  late Future<Map<String, int>> pointsFuture;

  @override
  Widget build(BuildContext context) {
    final levelState = context.watch<LevelState>();
    final level = context.watch<GameLevel>();
    final palette = context.watch<Palette>(); // Get Palette instance
    final settings = context.watch<SettingsController>();
    final playerProgress = context.watch<PlayerProgress>();
    final audioController = context.watch<AudioController>();

    final game = JennyGame()
      ..set(palette, levelState, audioController)
      ..setPlayerName(settings.playerName.value)
      ..setHighestLevelReached(playerProgress.highestLevelReached)
      ..setLevel(level.number);

    return Column(
      children: [
        Expanded(
          child: flame.GameWidget<JennyGame>(
            game: game,
          ),
        ),
      ],
    );
  }
}

class JennyGame extends flame.FlameGame with TapCallbacks {
  late Palette palette;
  late LevelState levelState;
  late AudioController audioController;
  late int points = 0;
  late int actions = 0;
  late int level;
  late int levelReached;
  late String name;

  late Sprite seaBackgroundSprite;
  late Sprite sea2BackgroundSprite;
  late Sprite sunBackgroundSprite;
  late Sprite sandBackgroundSprite;
  late Sprite cropBackgroundSprite;
  late Sprite loadingBackgroundSprite;
  late Sprite gameOverBackgroundSprite;
  late Sprite greeneryLevel1BackgroundSprite;
  late Sprite greeneryLevel2BackgroundSprite;
  late Sprite greeneryLevel3BackgroundSprite;

  late Sprite destroyerIdleSprite;
  late Sprite infantrymanIdleSprite;
  late ProjectViewComponent
      projectViewComponent; // Declare it here but don't instantiate
  // Remove Palette from the constructor and set it via a method
  void set(
      Palette palette, LevelState levelState, AudioController audioController) {
    this.palette = palette;
    this.levelState = levelState;
    this.audioController = audioController;
    // Instantiate the ProjectViewComponent here or in onLoad, now that palette is available
    projectViewComponent = ProjectViewComponent(
        palette: palette,
        levelState: levelState,
        audioController: audioController);
  }

  void setPoints(int i) {
    points = i;
  }

  void setActions(int i) {
    actions = i;
  }

  void setPlayerName(String s) {
    name = s;
  }

  void setHighestLevelReached(int i) {
    levelReached = i;
  }

  void setLevel(int i) {
    level = i;
  }

  Future<void> refreshData() async {
    try {
      var data = await DataFetcher.getGlobalCitizenData(name);
      points = data["points"] ?? 0;
      actions = data["actions"] ?? 0;
    } catch (e) {
      // Handle or log error
      print("Error fetching data: $e");
    }
  }

  void processWin() {
    levelState.setProgress((100).round());
    levelState.evaluate();
    audioController.playSfx(SfxType.win);
  }

  YarnProject yarnProject = YarnProject();

  @override
  FutureOr<void> onLoad() async {
    // Ensure palette has been set before proceeding
    seaBackgroundSprite =
        await loadSprite('backgrounds/bg_sea_rise_skyscrapper.webp');

    sea2BackgroundSprite = await loadSprite('backgrounds/bg_sea_rise.webp');

    sunBackgroundSprite = await loadSprite('backgrounds/bg_sun.webp');

    sandBackgroundSprite = await loadSprite('backgrounds/sand.webp');

    loadingBackgroundSprite =
        await loadSprite('backgrounds/bg_accessing_data.webp');

    cropBackgroundSprite = await loadSprite('backgrounds/bg_crop.webp');

    gameOverBackgroundSprite = await loadSprite('backgrounds/bg_gameover.webp');

    greeneryLevel1BackgroundSprite =
        await loadSprite('backgrounds/bg_greenery_level_1.webp');

    greeneryLevel2BackgroundSprite =
        await loadSprite('backgrounds/bg_greenery_level_2.webp');

    greeneryLevel3BackgroundSprite =
        await loadSprite('backgrounds/bg_greenery_level_3.webp');

    final destroyerIdleSpriteImage = await images.load('destroyer/Idle.png');
    final destroyerIdleSpriteSheet = SpriteSheet(
        image: destroyerIdleSpriteImage, srcSize: Vector2(128, 128));
    destroyerIdleSprite = destroyerIdleSpriteSheet.getSprite(0, 1);

    // final infantrymanIdleSpriteImage =
    //     await images.load('infantryman/Idle.png');
    // final infantrymanIdleSpriteSheet = SpriteSheet(
    //     image: infantrymanIdleSpriteImage, srcSize: Vector2(128, 128));

    // infantrymanIdleSprite = infantrymanIdleSpriteSheet.getSprite(0, 1);

    String seaDialogueData =
        await rootBundle.loadString('assets/yarn/sea.yarn');
    String sea2DialogueData =
        await rootBundle.loadString('assets/yarn/sea2.yarn');
    String sunDialogueData =
        await rootBundle.loadString('assets/yarn/sun.yarn');
    String sandDialogueData =
        await rootBundle.loadString('assets/yarn/sand.yarn');
    String cropDialogueData =
        await rootBundle.loadString('assets/yarn/crop.yarn');
    String loadingDialogueData =
        await rootBundle.loadString('assets/yarn/loading.yarn');
    String gameOverDialogData =
        await rootBundle.loadString('assets/yarn/game_over.yarn');
    String winLevel1DialogData =
        await rootBundle.loadString('assets/yarn/win_level1.yarn');
    String winLevel2DialogData =
        await rootBundle.loadString('assets/yarn/win_level2.yarn');
    String winLevel3DialogData =
        await rootBundle.loadString('assets/yarn/win_level3.yarn');
    String connectionDialogData =
        await rootBundle.loadString('assets/yarn/check_connection.yarn');
    String celebrationLevel1Data =
        await rootBundle.loadString('assets/yarn/celebration_level1.yarn');
    String celebrationLevel2Data =
        await rootBundle.loadString('assets/yarn/celebration_level2.yarn');
    String celebrationLevel3Data =
        await rootBundle.loadString('assets/yarn/celebration_level3.yarn');
    String restartData =
        await rootBundle.loadString('assets/yarn/restart.yarn');

    yarnProject
      ..functions.addFunction0("getPoints", getPoints)
      ..functions.addFunction0("getActions", getActions)
      ..functions.addFunction0("getPlayerName", getPlayerName)
      ..functions.addFunction0("getHighestLevelReached", getHighestLevelReached)
      ..functions.addFunction0("getLevel", getLevel)
      ..commands.addCommand0("refreshData", refreshData)
      ..commands.addCommand0("processWin", processWin)
      ..parse(seaDialogueData)
      ..parse(sea2DialogueData)
      ..parse(sunDialogueData)
      ..parse(sandDialogueData)
      ..parse(cropDialogueData)
      ..parse(loadingDialogueData)
      ..parse(gameOverDialogData)
      ..parse(winLevel1DialogData)
      ..parse(winLevel2DialogData)
      ..parse(winLevel3DialogData)
      ..parse(connectionDialogData)
      ..parse(celebrationLevel1Data)
      ..parse(celebrationLevel2Data)
      ..parse(celebrationLevel3Data)
      ..parse(restartData);

    var dialogueRunner = DialogueRunner(
      yarnProject: yarnProject,
      dialogueViews: [projectViewComponent],
    );
    dialogueRunner.startDialogue('Sea');
    add(projectViewComponent);
    return super.onLoad();
  }

  int getPoints() {
    return points;
  }

  int getActions() {
    return actions;
  }

  String getPlayerName() {
    return name;
  }

  int getHighestLevelReached() {
    return levelReached;
  }

  int getLevel() {
    return level;
  }
}
