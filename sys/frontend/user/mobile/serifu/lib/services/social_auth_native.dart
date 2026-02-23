import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';

import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'auth_service.dart';
import 'social_auth_service.dart';

SocialAuthService createSocialAuthService() => _NativeSocialAuthService();

class _NativeSocialAuthService extends SocialAuthService {
  @override
  Future<User> signInWithGoogle() async {
    final serverClientId = dotenv.env['GOOGLE_CLIENT_ID'];
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];

    final googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS ? iosClientId : null,
      serverClientId: serverClientId,
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled');
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw Exception('Failed to get Google ID token');
    }

    final result = await authRepository.googleLogin(
      idToken,
      name: account.displayName,
    );

    await authService.saveAuth(result.token, result.user.id);
    return result.user;
  }

  @override
  Future<User> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw Exception('Failed to get Apple identity token');
    }

    String? name;
    if (credential.givenName != null || credential.familyName != null) {
      name = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      if (name.isEmpty) name = null;
    }

    final result = await authRepository.appleLogin(
      identityToken,
      name: name,
    );

    await authService.saveAuth(result.token, result.user.id);
    return result.user;
  }

  @override
  Future<User> signInWithLine() async {
    final LoginResult loginResult;
    try {
      loginResult = await LineSDK.instance.login(
        scopes: ['profile'],
        option: Platform.isAndroid ? LoginOption(true, 'normal') : null,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCEL') {
        throw Exception('Login cancelled');
      }
      rethrow;
    }

    final accessToken = loginResult.accessToken.value;
    final profile = loginResult.userProfile;

    final result = await authRepository.lineLogin(
      accessToken,
      name: profile?.displayName,
    );

    await authService.saveAuth(result.token, result.user.id);
    return result.user;
  }

  @override
  bool get isAppleSignInAvailable => Platform.isIOS;

  @override
  bool get isLineSignInAvailable => true;
}
