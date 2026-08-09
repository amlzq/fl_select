import 'package:flutter/material.dart';

/// Native design dimensions of the simulated phone (before any [FittedBox]
/// scaling). The inner [MediaQuery] in the playground uses [kPhoneContentSize]
/// so overlay / dialog / bottom-sheet sizing matches the actual screen area.
const double kPhoneWidth = 390;
const double kPhoneHeight = 844;
const double kPhonePadding = 12;
const double kStatusBarHeight = 44;
const double kHomeIndicatorHeight = 28;

/// Actual inner screen area of the phone, i.e. the [ClipRRect] content box after
/// the [kPhonePadding] is removed from all sides, minus the status bar and home
/// indicator. This must match the [MediaQuery] size the playground injects for
/// the scoped [Navigator], otherwise dropdown overlays clamp against a screen
/// rect that is wider/taller than the real phone and overflow on the right /
/// bottom (getting clipped by the phone shell).
const double kPhoneContentWidth = kPhoneWidth - 2 * kPhonePadding;
const double kPhoneContentHeight =
    kPhoneHeight - 2 * kPhonePadding - kStatusBarHeight - kHomeIndicatorHeight;
const Size kPhoneContentSize = Size(kPhoneContentWidth, kPhoneContentHeight);

/// A purely decorative phone shell that hosts the demo screen. The dropdown
/// overlays / dialogs / bottom sheets are routed into a scoped [Navigator]
/// inside [screen], so they render within the phone rather than on the app's
/// root overlay.
///
/// [brightness] drives the simulated system chrome (status bar, home indicator
/// and the screen background) so it follows the preview's dark / light theme,
/// independent of the host app's own theme.
class PhoneFrame extends StatelessWidget {
  final Widget screen;
  final Brightness brightness;

  const PhoneFrame({
    required this.screen,
    this.brightness = Brightness.light,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? Colors.black : Colors.white;
    return Container(
      width: kPhoneWidth,
      height: kPhoneHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(46),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: ColoredBox(
          color: background,
          child: Column(
            children: <Widget>[
              _StatusBar(brightness: brightness),
              Expanded(child: screen),
              _HomeIndicator(brightness: brightness),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status-bar tint + icon color for the simulated phone chrome.
Color _chromeBackground(Brightness brightness) =>
    brightness == Brightness.dark ? Colors.black : Colors.white;
Color _chromeForeground(Brightness brightness) =>
    brightness == Brightness.dark ? Colors.white : Colors.black;

class _StatusBar extends StatelessWidget {
  final Brightness brightness;

  const _StatusBar({required this.brightness});

  @override
  Widget build(BuildContext context) {
    final fg = _chromeForeground(brightness);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: _chromeBackground(brightness),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            '9:41',
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: <Widget>[
              Icon(Icons.signal_cellular_alt, color: fg, size: 16),
              const SizedBox(width: 6),
              Icon(Icons.wifi, color: fg, size: 16),
              const SizedBox(width: 6),
              Icon(Icons.battery_full, color: fg, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  final Brightness brightness;

  const _HomeIndicator({required this.brightness});

  @override
  Widget build(BuildContext context) {
    final fg = _chromeForeground(brightness);
    return Container(
      height: 28,
      color: _chromeBackground(brightness),
      child: Center(
        child: Container(
          width: 120,
          height: 5,
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
