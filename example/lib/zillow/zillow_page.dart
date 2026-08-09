import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme_mode.dart';
import 'button.dart';
import 'dialog_bottom_sheet.dart';
import 'house_page.dart';
import 'view.dart';

class ZillowPage extends StatelessWidget {
  const ZillowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.zillow ?? 'Example'),
        actions: const [ThemeModeButton()],
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HousePage()),
                );
              },
              child: Text(l10n?.sell ?? 'PopupSelectBar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ButtonDemoPage(),
                  ),
                );
              },
              child: const Text('PopupSelectButton'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewPage()),
                );
              },
              child: const Text('View'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DialogBottomSheetDemoPage(),
                  ),
                );
              },
              child: const Text('Dialog & BottomSheet'),
            ),
          ],
        ),
      ),
    );
  }
}
