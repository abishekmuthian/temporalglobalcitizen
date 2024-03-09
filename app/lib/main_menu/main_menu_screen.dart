// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:temporal_global_citizen/settings/persistence/settings_persistence.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../settings/settings.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settingsController = context.watch<SettingsController>();
    final audioController = context.watch<AudioController>();

    return Scaffold(
      backgroundColor: palette.backgroundMain,
      body: ResponsiveScreen(
        squarishMainArea: Center(
          child: Transform.rotate(
            angle: -0.1,
            child: const Text(
              'Temporal Global Citizen!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 45,
                height: 1,
              ),
            ),
          ),
        ),
        rectangularMenuArea: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MyButton(
              onPressed: () {
                audioController.playSfx(SfxType.buttonTap);
                GoRouter.of(context).go('/play');
                // if (settingsController.playerName.value.isEmpty ||
                //     settingsController.playerName.value == "Player") {
                //   // Show the toast to set the name in settings
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(
                //       content: Text('Please set your player name in Settings'),
                //       duration: Duration(seconds: 2),
                //     ),
                //   );
                // } else {
                //   GoRouter.of(context).go('/play');
                // }
              },
              child: const Text('Play'),
            ),
            _gap,
            MyButton(
              onPressed: () => GoRouter.of(context).push('/settings'),
              child: const Text('Settings'),
            ),
            _gap,
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ValueListenableBuilder<bool>(
                valueListenable: settingsController.audioOn,
                builder: (context, audioOn, child) {
                  return IconButton(
                    onPressed: () => settingsController.toggleAudioOn(),
                    icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off),
                  );
                },
              ),
            ),
            _gap,
            const Text('Music by One Man Symphony'),
            _gap,
            const Text('Sfx by Filip, Pitarcus'),
            _gap,
          ],
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 10);
}
