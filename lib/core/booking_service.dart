import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';

const bookingServices = ['pt_men', 'pt_women', 'rehab', 'swim_private'];

/// الوقت الحالي بتوقيت الأكاديمية (UTC+3)
DateTime academyNow() =>
    DateTime.now().toUtc().add(const Duration(hours: 3));

String _two(int n) => n.toString().padLeft(2, '0');
String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

class Booking {
  final String id;
  final String uid;
  final String memberName;
  final String phone;
  final String service;
  final String date; // yyyy-MM-dd
  final String time; // HH:mm
  final String note;
  final String status; // pending/confirmed/rejected/cancelled/done
  final String trainerName;

  Booking({
    required this.id,
    required this.uid,
    required this.memberName,
    required this.phone,
    required this.service,
    required this.date,
    required this.time,
    required this.note,
    required this.status,
    required this.trainerName,
  });

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    String s(String k) => (m[k] ?? '').toString();
    return Booking(
      id: d.id,
      uid: s('uid'),
      memberName: s('memberName'),
      phone: s('phone'),
      service: s('service'),
      date: s('date'),
      time: s('time'),
      note: s('note'),
      status: s('status'),
      trainerName: s('trainerName'),
    );
  }

  String get sortKey => '$date $time';

  DateTime get day {
    final p = date.split('-');
    if (p.length != 3) return DateTime(2000);
    return DateTime(int.tryParse(p[0]) ?? 2000, int.tryParse(p[1]) ?? 1,
        int.tryParse(p[2]) ?? 1);
  }
}

class BookingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// حجوزاتي (الأحدث أولاً)
  static Stream<List<Booking>> mine() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .collection('bookings')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final l = s.docs.map(Booking.fromDoc).toList();
      l.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return l;
    });
  }

  /// كل الحجوزات للموظفين (الأقدم أولاً)
  static Stream<List<Booking>> all() {
    return _db.collection('bookings').snapshots().map((s) {
      final l = s.docs.map(Booking.fromDoc).toList();
      l.sort((a, b) => a.sortKey.compareTo(b.sortKey));
      return l;
    });
  }

  static Future<void> create({
    required String service,
    required String date,
    required String time,
    required String note,
  }) async {
    final u = FirebaseAuth.instance.currentUser!;
    final p = await ProfileService.load();
    await _db.collection('bookings').add({
      'uid': u.uid,
      'memberName': (p['name'] ?? u.displayName ?? '').toString(),
      'phone': (p['phone'] ?? '').toString(),
      'service': service,
      'date': date,
      'time': time,
      'note': note.trim(),
      'status': 'pending',
      'trainerName': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setStatus(String id, String status,
      {String? trainerName}) {
    final data = <String, dynamic>{'status': status};
    if (trainerName != null) data['trainerName'] = trainerName.trim();
    return _db.collection('bookings').doc(id).update(data);
  }
}