import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class Googleauthcontroller {
  // SharedPreferences key used to persist the last signed-in Google email
  // so it can be passed as login_hint on the next sign-in attempt.
  static const String _kLoginHintKey = 'google_login_hint';
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // _googleSignIn is only used on non-web platforms.
  // On web, GoogleSignIn.authenticate() is not supported; we use
  // FirebaseAuth.signInWithPopup() directly instead.
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static bool isInitialized = false;

  /// Initialises the GoogleSignIn plugin (Android only).
  /// On web this is a no-op because we delegate entirely to FirebaseAuth.
  static Future<void> initializeGoogleAuth() async {
    if (kIsWeb) return; // Not needed on web — signInWithPopup handles it.

    if (!isInitialized) {
      await _googleSignIn.initialize(
        serverClientId:
            '330146928360-mjbglcl0s022qqd9l739c6j7bhvmeruu.apps.googleusercontent.com',
      );
      isInitialized = true;
    }
  }

  /// Upserts the authenticated [user] into the Supabase `users` table.
  /// Called by both the web and Android sign-in paths to guarantee
  /// that exactly the same data is written on every platform.
  static Future<void> _upsertUser(User user) async {
    await Supabase.instance.client.from('users').upsert({
      'id': user.uid,
      'name': user.displayName ?? 'User',
      'email': user.email,
      'photo_url': user.photoURL ?? '',
      'role': 'user',
      'last_login': DateTime.now().toIso8601String(),
    });
  }

  /// Signs the user in with Google.
  ///
  /// Returns a [UserCredential] on success.
  /// Returns **`null`** when the user cancels the account picker — no exception
  /// is thrown in that case, so the VS Code debugger never pauses on cancel.
  /// Throws for genuine errors (network failure, Firebase error, etc.).
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // ── WEB ──────────────────────────────────────────────────────────────────
      // GoogleSignIn.authenticate() is not supported on Flutter Web.
      // FirebaseAuth.signInWithPopup() opens the native browser Google
      // account-picker popup and returns a UserCredential directly, so no
      // intermediate token exchange is required.
      if (kIsWeb) {
        // Read the previously used account email, if any.
        // This is used as a hint so the browser pre-highlights that account
        // in the picker — the full list is still shown (prompt: select_account).
        final prefs = await SharedPreferences.getInstance();
        final loginHint = prefs.getString(_kLoginHintKey);

        // 'prompt: select_account' forces the full Google account chooser to
        // appear every time, showing ALL accounts signed into the browser —
        // identical to Android's native account picker behaviour.
        final params = <String, String>{'prompt': 'select_account'};
        if (loginHint != null && loginHint.isNotEmpty) {
          // Pre-highlights the previously used account at the top of the list.
          params['login_hint'] = loginHint;
        }

        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile')
          ..setCustomParameters(params);

        try {
          final UserCredential userCredential = await _auth.signInWithPopup(
            googleProvider,
          );

          final User? user = userCredential.user;

          if (user != null) {
            // Remember this account so we can hint at it on the next sign-in.
            await prefs.setString(_kLoginHintKey, user.email ?? '');
            await _upsertUser(user);

            return userCredential;
          }

          throw FirebaseAuthException(
            code: 'user-null',
            message: 'User is null after sign in',
          );
        } on FirebaseAuthException catch (e) {
          // The user closed the browser popup — return null so the caller
          // knows it was a voluntary cancel, not a real failure.
          if (e.code == 'popup-closed-by-user' ||
              e.code == 'cancelled-popup-request') {
            return null;
          }
          rethrow;
        }
      }

      // ── ANDROID ──────────────────────────────────────────────────────────────
      await initializeGoogleAuth();

      late final GoogleSignInAccount gUser;
      try {
        gUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        // The user dismissed the account picker — return null (not an error).
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return null;
        }
        rethrow;
      }

      // getting id token
      final idToken = gUser.authentication.idToken;
      final authorizationClient = gUser.authorizationClient;

      // authorize the user
      GoogleSignInClientAuthorization? authorization =
          await authorizationClient.authorizationForScopes(['email', 'profile']);

      // getting access token
      final accessToken = authorization!.accessToken;

      // credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // sign in
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        await _upsertUser(user);

        return userCredential;
      }

      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User is null after sign in',
      );
    } catch (e) {
      debugPrint('GoogleAuthController.signInWithGoogle error: $e');
      rethrow;
    }
  }

  // signout
  static Future<void> signOut() async {
    try {
      if (kIsWeb) {
        // Clear the stored account hint so the next sign-in starts fresh
        // with a clean account picker (no pre-selection).
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kLoginHintKey);
      } else {
        // GoogleSignIn.signOut() is only meaningful on non-web platforms.
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('GoogleAuthController.signOut error: $e');
      rethrow;
    }
  }
}
