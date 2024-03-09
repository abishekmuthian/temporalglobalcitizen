// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:temporal_global_citizen/game_internals/data_fetcher.dart';
import 'package:temporal_global_citizen/game_internals/level_state.dart';
import 'package:temporal_global_citizen/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../game_internals/score.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class WinGameScreen extends StatelessWidget {
  final Score score;
  late String walletUrl;

  WinGameScreen({
    super.key,
    required this.score,
  });

  Future<void> _fetchAndLaunchUrl(BuildContext context, Score score) async {
    final settings = context.read<SettingsController>();
    try {
      var data = await DataFetcher.getWalletData(
        settings.playerName.value,
        score.level,
        score.score,
        score.formattedTime,
      );
      final walletUrl = data["url"] ?? '';
      if (!await launchUrl(Uri.parse(walletUrl))) {
        throw 'Could not launch $walletUrl';
      }
    } catch (e) {
      // Handle or log error
      print("Error fetching data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open the wallet URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    const gap = SizedBox(height: 10);

    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
                'assets/images/badges/badging_app_planetdefender${score.level}.png__300x300_subsampling-2.png'), // Your image file
            gap,
            Center(
              child: Text(
                'You have Planet Defender Level ${score.level} Badge!',
                style: TextStyle(fontFamily: 'PressStart2P', fontSize: 20),
              ),
            ),
            gap,
            Center(
              child: Text(
                'Score: ${score.score}\n'
                'Time: ${score.formattedTime}',
                style:
                    const TextStyle(fontFamily: 'PressStart2P', fontSize: 15),
              ),
            ),
            gap,
            InkWell(
              onTap: () => _fetchAndLaunchUrl(context, score),
              child: Image.asset(
                  'assets/images/wallet/enGB_add_to_google_wallet_add-wallet-badge.png'), // Replace with your image asset path
            ),
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () {
            GoRouter.of(context).go('/play');
          },
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
