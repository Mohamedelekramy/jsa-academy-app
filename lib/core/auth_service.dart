import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String gender, // male | female
    required String password,
    required String lang,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'gender': gender,
      'role': 'member',
      'lang': lang,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await cred.user!.updateDisplayName(name.trim());
  }

  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  static Future<void> logout() => _auth.signOut();

  static Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(
      String uid) =>
      _db.collection('users').doc(uid).snapshots();

  /// بيحوّل خطأ Firebase لمفتاح نص (بيترجم حسب اللغة)
  static String errorKey(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'errUserNotFound';
        case 'wrong-password':
        case 'invalid-credential':
          return 'errWrongPass';
        case 'invalid-email':
          return 'errEmail';
        case 'email-already-in-use':
          return 'errEmailInUse';
        case 'weak-password':
          return 'errWeakPass';
        case 'network-request-failed':
          return 'errNetwork';
        case 'too-many-requests':
          return 'errTooMany';
      }
    }
    return 'errGeneric';
  }
}