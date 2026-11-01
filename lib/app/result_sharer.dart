import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Hands a rendered result card to the platform share sheet (or, on the web,
/// the browser's share or download).
abstract interface class ResultSharer {
  Future<void> share({required Uint8List png, required String text});
}

class PlatformResultSharer implements ResultSharer {
  const PlatformResultSharer();

  @override
  Future<void> share({required Uint8List png, required String text}) =>
      SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: 'quizorbit-score.png',
            ),
          ],
        ),
      );
}
