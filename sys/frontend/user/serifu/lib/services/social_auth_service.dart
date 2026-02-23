import '../models/user.dart';
import 'social_auth_stub.dart'
    if (dart.library.io) 'social_auth_native.dart';

abstract class SocialAuthService {
  Future<User> signInWithGoogle();
  Future<User> signInWithApple();
  Future<User> signInWithLine();
  bool get isAppleSignInAvailable;
  bool get isLineSignInAvailable;
}

final SocialAuthService socialAuthService = createSocialAuthService();
