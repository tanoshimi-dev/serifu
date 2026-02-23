import 'dart:io';

bool get isMobileNative => Platform.isIOS || Platform.isAndroid;
bool get isIOSNative => Platform.isIOS;
bool get isAndroidNative => Platform.isAndroid;
