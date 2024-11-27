import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtil {
  static bool get isDesktopPlatform {
    return kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}
