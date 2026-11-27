import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// بيانات العضو الحالية
  static Future<Map<String, dynamic>> load() async {
    final u = FirebaseAuth.instance.currentUser!;
    final d = await _db.collection('users').doc(u.uid).get();
    return d.data() ?? <String, dynamic>{};
  }

  /// حفظ بيانات الحساب
  static Future<void> update({
    required String name,
    required String phone,
    required String address,
    String? photoB64,
    required bool photoChanged,
  }) async {
    final u = FirebaseAuth.instance.currentUser!;
    final data = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
    };
    if (photoChanged) {
      data['photoB64'] =
      data['photoB64'] = photoB64 ?? FieldValue.delete();
    }
    await _db.collection('users').doc(u.uid).update(data);
    await u.updateDisplayName(name.trim());
  }

  /// تغيير كلمة السر (لازم القديمة الأول)
  static Future<void> changePassword({
    required String oldPass,
    required String newPass,
  }) async {
    final u = FirebaseAuth.instance.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: u.email!,
      password: oldPass,
    );
    await u.reauthenticateWithCredential(cred);
    await u.updatePassword(newPass);
  }
}