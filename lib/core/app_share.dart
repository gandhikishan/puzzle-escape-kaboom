import 'package:share_plus/share_plus.dart';

/// Centralised app-sharing so the message/link is defined in one place and the
/// native share sheet (WhatsApp, Messages, Facebook, etc.) can be invoked from
/// anywhere in the UI.
class AppShare {
  const AppShare._();

  static const String _packageId = 'com.puzzleescape.kaboom';
  static const String storeUrl =
      'https://play.google.com/store/apps/details?id=$_packageId';

  /// Public privacy policy URL (also submitted to the Play Console).
  static const String privacyUrl =
      'https://gandhikishan.github.io/puzzle-escape-kaboom/';

  static const String _message =
      'I\'m hooked on Puzzle Escape - Kaboom! 💣 Tap bombs, clear the board, '
      'and beat 1000+ brain-teasing stages. Can you out-puzzle me?\n\n$storeUrl';

  /// Opens the OS share sheet so the player can share via any installed app.
  static Future<void> shareApp() {
    return SharePlus.instance.share(
      ShareParams(
        text: _message,
        subject: 'Puzzle Escape - Kaboom',
      ),
    );
  }
}
