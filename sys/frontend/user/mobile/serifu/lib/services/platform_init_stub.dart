import 'package:flutter/widgets.dart';
import 'platform_init_service.dart';

PlatformInitService createPlatformInitService() => _WebPlatformInitService();

class _WebPlatformInitService extends PlatformInitService {
  @override
  Future<void> initialize(WidgetsBinding widgetsBinding) async {
    // No-op on web: no native splash, no LINE SDK setup
  }

  @override
  void removeSplash() {
    // No-op on web: splash handled by HTML
  }
}
