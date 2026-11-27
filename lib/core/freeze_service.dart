import 'package:cloud_firestore/cloud_firestore.dart';

import 'plans_service.dart';

/// اشتراك العضو + بيانات التجميد
class MySub {
  final Sub sub;
  final bool freezeUsed;
  final DateTime? frozenUntil;

  const MySub(this.sub, this.freezeUsed, this.frozenUntil);

  bool get isFrozen =>
      frozenUntil != null && frozenUntil!.isAfter(DateTime.now());

  /// يقدر يجمّد: فعّال، له تاريخ انتهاء، مش خدمة، ولسه ما جمّدش
  bool get canFreeze =>
      sub.effectiveStatus == 'active' &&
          sub.endDate != null &&
          sub.kind != 'service' &&
          !freezeUsed;
}

class FreezeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<List<MySub>> mine(String uid) {
    return _db
        .collection('subscriptions')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) {
      final m = d.data();
      return MySub(
        Sub.fromDoc(d),
        m['freezeUsed'] == true,
        (m['frozenUntil'] as Timestamp?)?.toDate(),
      );
    }).toList());
  }

  /// تجميد أسبوع (مرة واحدة) مع تمديد تاريخ الانتهاء 7 أيام
  static Future<void> freeze(MySub m) async {
    final end = m.sub.endDate!.toUtc();
    final now = DateTime.now().toUtc();
    await _db.collection('subscriptions').doc(m.sub.id).update({
      'endDate': Timestamp.fromDate(end.add(const Duration(days: 7))),
      'freezeUsed': true,
      'frozenFrom': FieldValue.serverTimestamp(),
      'frozenUntil': Timestamp.fromDate(now.add(const Duration(days: 7))),
    });
  }
}