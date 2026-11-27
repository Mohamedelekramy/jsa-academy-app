import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// اشتراك من وجهة نظر الموظف
class StaffSub {
  final String id;
  final String uid;
  final String memberName;
  final String clubId;
  final String groupAr;
  final String groupEn;
  final String titleAr;
  final String titleEn;
  final String kind;
  final String status;
  final String paymentMethod;
  final int months;
  final int sessions;
  final num price;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;

  // بيانات التجميد
  final bool freezeUsed;
  final DateTime? frozenFrom;
  final DateTime? frozenUntil;

  const StaffSub({
    required this.id,
    required this.uid,
    required this.memberName,
    required this.clubId,
    required this.groupAr,
    required this.groupEn,
    required this.titleAr,
    required this.titleEn,
    required this.kind,
    required this.status,
    required this.paymentMethod,
    required this.months,
    required this.sessions,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.freezeUsed = false,
    this.frozenFrom,
    this.frozenUntil,
  });

  /// مجمّد حالياً (فترة التجميد لسه سارية)
  bool get isFrozen =>
      frozenUntil != null && frozenUntil!.isAfter(DateTime.now());

  factory StaffSub.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return StaffSub(
      id: d.id,
      uid: (m['uid'] ?? '') as String,
      memberName: (m['memberName'] ?? '') as String,
      clubId: (m['clubId'] ?? '') as String,
      groupAr: (m['groupAr'] ?? '') as String,
      groupEn: (m['groupEn'] ?? '') as String,
      titleAr: (m['titleAr'] ?? '') as String,
      titleEn: (m['titleEn'] ?? '') as String,
      kind: (m['kind'] ?? 'months') as String,
      status: (m['status'] ?? 'pending') as String,
      paymentMethod: (m['paymentMethod'] ?? 'cash') as String,
      months: (m['months'] as num?)?.toInt() ?? 0,
      sessions: (m['sessions'] as num?)?.toInt() ?? 0,
      price: (m['price'] as num?) ?? 0,
      startDate: (m['startDate'] as Timestamp?)?.toDate(),
      endDate: (m['endDate'] as Timestamp?)?.toDate(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      freezeUsed: m['freezeUsed'] == true,
      frozenFrom: (m['frozenFrom'] as Timestamp?)?.toDate(),
      frozenUntil: (m['frozenUntil'] as Timestamp?)?.toDate(),
    );
  }
}

class StaffService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// كل الاشتراكات بحالة معينة
  static Stream<List<StaffSub>> byStatus(String status) {
    return _db
        .collection('subscriptions')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((s) => s.docs.map(StaffSub.fromDoc).toList());
  }

  /// إضافة شهور لتاريخ (مع مراعاة نهاية الشهر)
  static DateTime addMonths(DateTime d, int m) {
    final y = d.year + ((d.month - 1 + m) ~/ 12);
    final mo = (d.month - 1 + m) % 12 + 1;
    final lastDay = DateTime(y, mo + 1, 0).day;
    return DateTime(y, mo, d.day > lastDay ? lastDay : d.day);
  }

  /// تفعيل اشتراك بعد استلام الدفع
  static Future<void> activate(
      StaffSub s,
      DateTime start,
      String method,
      ) async {
    final startDay = DateTime(start.year, start.month, start.day);
    DateTime? end;
    if (s.kind != 'service') {
      end = addMonths(startDay, s.months)
          .add(const Duration(hours: 23, minutes: 59));
    }
    await _db.collection('subscriptions').doc(s.id).update({
      'status': 'active',
      'startDate': Timestamp.fromDate(startDay),
      'endDate': end == null ? null : Timestamp.fromDate(end),
      'paymentMethod': method,
      'sessionsLeft': s.sessions,
      'paidAt': FieldValue.serverTimestamp(),
      'activatedBy': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  /// رفض طلب
  static Future<void> reject(String id) async {
    await _db.collection('subscriptions').doc(id).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  /// رقم جوال العضو
  static Future<String> phoneOf(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return (d.data()?['phone'] ?? '') as String;
  }
}