import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class Googleauthcontroller {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static bool isInitialized = false;

  static Future<void> initializeGoogleAuth() async {
    if (!isInitialized) {
      await _googleSignIn.initialize(
        serverClientId:'330146928360-mjbglcl0s022qqd9l739c6j7bhvmeruu.apps.googleusercontent.com'
      );
      isInitialized = true;
    }
    
  }

  static Future<UserCredential> signInWithGoogle() async {
    try {
      await initializeGoogleAuth();

      final GoogleSignInAccount gUser = await _googleSignIn.authenticate();

      // getting id token
      final idToken = gUser.authentication.idToken;
      final authorizationClient = gUser.authorizationClient;

      // authorize the user
      GoogleSignInClientAuthorization? authorization = await authorizationClient
          .authorizationForScopes(['email', 'profile']);

      // getting access token
      final accessToken = authorization!.accessToken;
      // if(accessToken == null){
      //   throw FirebaseAuthException(code: 'error',message: 'error');
      // }

      // credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // sign in
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .upsert({
          'id': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email,
          'photo_url': user.photoURL ?? '',
          'role': 'user',
          'last_login': DateTime.now().toIso8601String(),
        });

        return userCredential;
      }
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User is null after sign in',
      );
    } catch (e) {
      print("Error: $e");
      throw e;
    }
  }

  // signout
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Error signingout: $e");
      throw e;
    }
  }
}
