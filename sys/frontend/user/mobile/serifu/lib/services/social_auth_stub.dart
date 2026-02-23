import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'auth_service.dart';
import 'social_auth_service.dart';

SocialAuthService createSocialAuthService() => _WebSocialAuthService();

class _WebSocialAuthService extends SocialAuthService {
  @override
  Future<User> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled');
    }

    final authentication = await account.authentication;
    // Web returns accessToken (not idToken) via OAuth2 implicit flow
    final token = authentication.idToken ?? authentication.accessToken;
    if (token == null) {
      throw Exception('Failed to get Google token');
    }

    final result = await authRepository.googleLogin(
      token,
      name: account.displayName,
    );

    await authService.saveAuth(result.token, result.user.id);
    return result.user;
  }

  @override
  Future<User> signInWithApple() async {
    throw UnsupportedError('Apple Sign In is not available on web');
  }

  @override
  Future<User> signInWithLine() async {
    throw UnsupportedError('LINE Sign In is not available on web');
  }

  @override
  bool get isAppleSignInAvailable => false;

  @override
  bool get isLineSignInAvailable => false;
}
