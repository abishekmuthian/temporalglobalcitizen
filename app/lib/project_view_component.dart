import 'dart:async';

import 'package:temporal_global_citizen/audio/audio_controller.dart';
import 'package:temporal_global_citizen/audio/sounds.dart';
import 'package:temporal_global_citizen/game_internals/level_state.dart';
import 'package:temporal_global_citizen/play_session/game_widget.dart';
import 'package:temporal_global_citizen/style/palette.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

class ProjectViewComponent extends PositionComponent
    with DialogueView, HasGameRef<JennyGame> {
  final Palette palette;
  final LevelState levelState;
  final AudioController audioController;
  late final TextBoxComponent mainDialogueTextComponent;
  late final TextPaint dialoguePaint;
  final background = SpriteComponent();
  final protagonist = SpriteComponent();
  late Sprite bgSpriteBeforeVisit;

  late final ButtonComponent forwardButtonComponent;
  Completer<void> _forwardCompleter = Completer();
  Completer<int> _choiceCompleter = Completer<int>();

  List<ButtonComponent> optionsList = [];

  ProjectViewComponent(
      {required this.palette,
      required this.levelState,
      required this.audioController});

  @override
  FutureOr<void> onLoad() {
    dialoguePaint = TextPaint(
        style: TextStyle(
            fontFamily: 'PressStart2P',
            color: palette.terminalGreen,
            backgroundColor: Color.fromARGB(250, 250, 250, 250),
            fontSize: 22));
    background
      ..sprite = gameRef.seaBackgroundSprite
      ..size = gameRef.size;
    protagonist
      ..sprite = gameRef.destroyerIdleSprite
      ..size = Vector2(128, 128);

    forwardButtonComponent = ButtonComponent(
        button: PositionComponent(),
        size: gameRef.size,
        onPressed: () {
          audioController.playSfx(SfxType.move);
          if (!_forwardCompleter.isCompleted) {
            _forwardCompleter.complete();
          }
        });
    mainDialogueTextComponent = TextBoxComponent(
      textRenderer: dialoguePaint,
      text: '',
      // Horizontally center the text box. Assuming maxWidth is the limiting factor for the box width.
      position: Vector2(50, gameRef.size.y * .2),
      boxConfig: TextBoxConfig(maxWidth: gameRef.size.x * .8),
    );
    addAll([
      background,
      protagonist,
      // supportingCharacter,
      forwardButtonComponent,
      mainDialogueTextComponent
    ]);
    return super.onLoad();
  }

  @override
  FutureOr<bool> onLineStart(DialogueLine line) async {
    _forwardCompleter = Completer();
    await _advance(line);
    return super.onLineStart(line);
  }

  @override
  FutureOr<int?> onChoiceStart(DialogueChoice choice) async {
    _choiceCompleter = Completer<int>();
    forwardButtonComponent.removeFromParent();
    mainDialogueTextComponent.text = '';
    for (int i = 0; i < choice.options.length; i++) {
      optionsList.add(ButtonComponent(
          position: Vector2(50, i * 150 + 150), // Increase spacing
          button: TextBoxComponent(
            text: 'Choice ${i + 1}: ${choice.options[i].text}',
            textRenderer: dialoguePaint,
            boxConfig: TextBoxConfig(
              maxWidth: gameRef.size.x * .8,
            ),
          ),
          onPressed: () {
            if (!_choiceCompleter.isCompleted) {
              _choiceCompleter.complete(i);
            }
          }));
    }
    addAll(optionsList);
    await _getChoice(choice);
    return _choiceCompleter.future;
  }

  @override
  FutureOr<void> onChoiceFinish(DialogueOption option) {
    // mainDialogueTextComponent.text = 'decision is ${option.text}';
    audioController.playSfx(SfxType.confirm);
    removeAll(optionsList);
    optionsList = [];
    add(forwardButtonComponent);
  }

  @override
  FutureOr<void> onNodeStart(Node node) {
    switch (node.title) {
      case 'Sea':
        background.sprite = gameRef.seaBackgroundSprite;
        bgSpriteBeforeVisit = gameRef.seaBackgroundSprite;
        break;
      case 'Sea2':
        background.sprite = gameRef.sea2BackgroundSprite;
        bgSpriteBeforeVisit = gameRef.sea2BackgroundSprite;
        break;
      case 'Sun':
        background.sprite = gameRef.sunBackgroundSprite;
        bgSpriteBeforeVisit = gameRef.sunBackgroundSprite;
        break;
      case 'Sand':
        background.sprite = gameRef.sandBackgroundSprite;
        bgSpriteBeforeVisit = gameRef.sandBackgroundSprite;
        break;
      case 'Crop':
        background.sprite = gameRef.cropBackgroundSprite;
        bgSpriteBeforeVisit = gameRef.cropBackgroundSprite;
        break;
      case 'WinLevel1':
        background.sprite = gameRef.greeneryLevel1BackgroundSprite;
        audioController.playSfx(SfxType.perfect);
        break;
      case 'WinLevel2':
        background.sprite = gameRef.greeneryLevel2BackgroundSprite;
        audioController.playSfx(SfxType.perfect);
        break;
      case 'WinLevel3':
        background.sprite = gameRef.greeneryLevel3BackgroundSprite;
        audioController.playSfx(SfxType.perfect);

        break;
      case 'Loading':
        background.sprite = gameRef.loadingBackgroundSprite;
        break;
      case 'GameOver':
        background.sprite = gameRef.gameOverBackgroundSprite;
        audioController.playSfx(SfxType.wrong);
        break;
      case 'CelebrationLevel1':
        background.sprite = gameRef.greeneryLevel1BackgroundSprite;
        break;
      case 'CelebrationLevel2':
        background.sprite = gameRef.greeneryLevel2BackgroundSprite;
        break;
      case 'CelebrationLevel3':
        background.sprite = gameRef.greeneryLevel3BackgroundSprite;
        break;
    }
  }

  @override
  FutureOr<void> onNodeFinish(Node node) {
    switch (node.title) {
      case 'Sea':
        print("Sea Node Finished");
        break;
      case 'Sun':
        print("Sun Node Finished");
        break;
      case 'Sand':
        print("Sand Node Finished");
        break;
      case 'WinLevel1':
        break;
      case 'Loading':
        print("Loading Node Finished");
        background.sprite = bgSpriteBeforeVisit;
        break;
    }
  }

  Future<void> _getChoice(DialogueChoice choice) async {
    return _forwardCompleter.future;
  }

  Future<void> _advance(DialogueLine line) async {
    var characterName = line.character?.name ?? '';
    var dialogueLineText = '$characterName: ${line.text}';
    mainDialogueTextComponent.text = dialogueLineText;
    debugPrint('debug $dialogueLineText');
    return _forwardCompleter.future;
  }
}
