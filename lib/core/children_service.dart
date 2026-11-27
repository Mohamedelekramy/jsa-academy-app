import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'plans_service.dart';

/// عمر بالسنين من تاريخ الميلاد
int ageOf(DateTime birth) {
  final now = DateTime.now();
  var a = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    a--;
  }
  return a;
}

/// الفئة حسب العمر: A (6-9) ، B (10-13) ، C (14-16) ، '-' خارج الفئات
String categoryOf(int age) {
  if (age >= 6 && age <= 9) return 'A';
  if (age >= 10 && age <= 13) return 'B';
  if (age >= 14 && age <= 16) return 'C';
  return '-';
}

class Child {
  final String id;
  final String parentUid;
  final String name;
  final String gender; // male | female
  final DateTime birthDate;
  final DateTime? createdAt;

  const Child({
    required this.id,
    required this.parentUid,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.createdAt,
  });

  int get age => ageOf(birthDate);
  String get category => categoryOf(age);

  factory Child.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Child(
      id: d.id,
      parentUid: (m['parentUid'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      gender: (m['gender'] ?? 'male') as String,
      birthDate:
      (m['birthDate'] as Timestamp?)?.toDate() ?? DateTime(2015, 1, 1),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChildrenService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<List<Child>> myChildren(String uid) {
    return _db
        .collection('children')
        .where('parentUid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map(Child.fromDoc).toList();
      list.sort((a, b) => (a.createdAt ?? DateTime.now())
          .compareTo(b.createdAt ?? DateTime.now()));
      return list;
    });
  }

  static Future<void> add({
    required String name,
    required DateTime birthDate,
    required String gender,
  }) async {
    final u = FirebaseAuth.instance.currentUser!;
    await _db.collection('children').add({
      'parentUid': u.uid,
      'name': name.trim(),
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> update(
      String id, {
        required String name,
        required DateTime birthDate,
        required String gender,
      }) async {
    await _db.collection('children').doc(id).update({
      'name': name.trim(),
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender,
    });
  }

  /// طلب اشتراك لطفل (بيتسجل بانتظار التفعيل)
  static Future<void> requestKidsSubscription({
    required Plan plan,
    required Child child,
    required String parentName,
    String paymentMethod = 'cash',
  }) async {
    final u = FirebaseAuth.instance.currentUser!;
    await _db.collection('subscriptions').add({
      'uid': u.uid,
      // الاسم اللي بيظهر للموظفين: الطفل (ولي الأمر)
      'memberName': '${child.name} ($parentName)',
      'parentName': parentName,
      'childId': child.id,
      'childName': child.name,
      'childCategory': child.category,
      'planId': plan.id,
      'clubId': plan.clubId,
      'groupKey': plan.groupKey,
      'groupAr': plan.groupAr,
      'groupEn': plan.groupEn,
      'titleAr': plan.titleAr,
      'titleEn': plan.titleEn,
      'kind': plan.kind,
      'months': plan.months,
      'sessions': plan.sessions,
      'sessionsLeft': plan.sessions,
      'price': plan.price,
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'startDate': null,
      'endDate': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}