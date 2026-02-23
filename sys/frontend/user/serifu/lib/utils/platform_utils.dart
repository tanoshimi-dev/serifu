import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_native.dart';

bool get isWeb => kIsWeb;
bool get isMobile => !kIsWeb && isMobileNative;
bool get isIOS => !kIsWeb && isIOSNative;
bool get isAndroid => !kIsWeb && isAndroidNative;
bool get isDesktopWeb => kIsWeb;
