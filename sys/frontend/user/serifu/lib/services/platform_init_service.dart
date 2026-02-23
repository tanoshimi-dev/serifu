import 'package:flutter/widgets.dart';
import 'platform_init_stub.dart'
    if (dart.library.io) 'platform_init_native.dart';

abstract class PlatformInitService {
  Future<void> initialize(WidgetsBinding widgetsBinding);
  void removeSplash();
}

final PlatformInitService platformInitService = createPlatformInitService();
