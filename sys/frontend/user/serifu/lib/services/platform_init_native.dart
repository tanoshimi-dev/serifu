import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'platform_init_service.dart';

PlatformInitService createPlatformInitService() => _NativePlatformInitService();

class _NativePlatformInitService extends PlatformInitService {
  @override
  Future<void> initialize(WidgetsBinding widgetsBinding) async {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    await LineSDK.instance.setup(dotenv.env['LINE_CHANNEL_ID']!);
  }

  @override
  void removeSplash() {
    FlutterNativeSplash.remove();
  }
}
