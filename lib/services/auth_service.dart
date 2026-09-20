import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void>? _googleInitialization;

  // This is the WEB OAuth client ID from google-services.json
  // client_type: 3
  static const String _googleServerClientId =
      '401476257902-0daofm4edl61qg6olordonam3s688vhi.apps.googleusercontent.com';

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ------------------------------------------------
  // EMAIL + PASSWORD
  // ------------------------------------------------

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ------------------------------------------------
  // GOOGLE INITIALIZATION
  // ------------------------------------------------

  Future<void> _ensureGoogleInitialized() async {
    final existing = _googleInitialization;

    if (existing != null) {
      await existing;
      return;
    }

    final initialization = _googleSignIn.initialize(
      serverClientId: _googleServerClientId,
    );

    _googleInitialization = initialization;

    try {
      await initialization;
    } catch (_) {
      if (identical(_googleInitialization, initialization)) {
        _googleInitialization = null;
      }

      rethrow;
    }
  }

  // ------------------------------------------------
  // GOOGLE
  // ------------------------------------------------

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleUser = await _googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'google-missing-id-token',
        message: 'Google did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return _auth.signInWithCredential(credential);
  }

  // ------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------

  Future<void> signOut() async {
    await _auth.signOut();

    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
