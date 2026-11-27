import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// باقة / خيار اشتراك
class Plan {
  final String id;
  final String clubId;
  final String groupKey;
  final String groupAr;
  final String groupEn;
  final String kind; // months | sessions | service
  final String titleAr;
  final String titleEn;
  final String noteAr;
  final String noteEn;
  final int months;
  final int sessions;
  final int order;
  final bool active;
  final num price;

  const Plan({
    required this.id,
    required this.clubId,
    required this.groupKey,
    required this.groupAr,
    required this.groupEn,
    required this.kind,
    required this.titleAr,
    required this.titleEn,
    required this.noteAr,
    required this.noteEn,
    required this.months,
    required this.sessions,
    required this.order,
    required this.active,
    required this.price,
  });

  factory Plan.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Plan(
      id: d.id,
      clubId: (m['clubId'] ?? '') as String,
      groupKey: (m['groupKey'] ?? '') as String,
      groupAr: (m['groupAr'] ?? '') as String,
      groupEn: (m['groupEn'] ?? '') as String,
      kind: (m['kind'] ?? 'months') as String,
      titleAr: (m['titleAr'] ?? '') as String,
      titleEn: (m['titleEn'] ?? '') as String,
      noteAr: (m['noteAr'] ?? '') as String,
      noteEn: (m['noteEn'] ?? '') as String,
      months: (m['months'] as num?)?.toInt() ?? 0,
      sessions: (m['sessions'] as num?)?.toInt() ?? 0,
      order: (m['order'] as num?)?.toInt() ?? 0,
      active: (m['active'] ?? true) as bool,
      price: (m['price'] as num?) ?? 0,
    );
  }

  String group(bool ar) => ar ? groupAr : groupEn;
  String title(bool ar) => ar ? titleAr : titleEn;
  String note(bool ar) => ar ? noteAr : noteEn;
}

/// اشتراك عضو
class Sub {
  final String id;
  final String clubId;
  final String groupAr;
  final String groupEn;
  final String childName;
  final String titleAr;
  final String titleEn;
  final String kind;
  final String status; // pending | active | expired | frozen | cancelled
  final int months;
  final int sessions;
  final int sessionsLeft;
  final num price;
  final DateTime? endDate;
  final DateTime? createdAt;

  const Sub({
    required this.id,
    required this.clubId,
    required this.groupAr,
    required this.groupEn,
    required this.childName,
    required this.titleAr,
    required this.titleEn,
    required this.kind,
    required this.status,
    required this.months,
    required this.sessions,
    required this.sessionsLeft,
    required this.price,
    required this.endDate,
    required this.createdAt,
  });

  factory Sub.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Sub(
      id: d.id,
      clubId: (m['clubId'] ?? '') as String,
      groupAr: (m['groupAr'] ?? '') as String,
      groupEn: (m['groupEn'] ?? '') as String,
      titleAr: (m['titleAr'] ?? '') as String,
      titleEn: (m['titleEn'] ?? '') as String,
      childName: (m['childName'] ?? '') as String,
      kind: (m['kind'] ?? 'months') as String,
      status: (m['status'] ?? 'pending') as String,
      months: (m['months'] as num?)?.toInt() ?? 0,
      sessions: (m['sessions'] as num?)?.toInt() ?? 0,
      sessionsLeft: (m['sessionsLeft'] as num?)?.toInt() ?? 0,
      price: (m['price'] as num?) ?? 0,
      endDate: (m['endDate'] as Timestamp?)?.toDate(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
  /// الحالة الفعلية (الفعّال اللي عدّى تاريخه يبقى منتهي)
  String get effectiveStatus {
    if (status == 'active' &&
        endDate != null &&
        endDate!.isBefore(DateTime.now())) {
      return 'expired';
    }
    return status;
  }
}

class PlansService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// باقات نادي معين (مرتبة)
  static Stream<List<Plan>> plansStream(String clubId) {
    return _db
        .collection('plans')
        .where('clubId', isEqualTo: clubId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(Plan.fromDoc).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  /// اشتراكات العضو (الأحدث أولاً)
  static Stream<List<Sub>> mySubs(String uid) {
    return _db
        .collection('subscriptions')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map(Sub.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// طلب اشتراك (بيتسجل بانتظار التفعيل)
  static Future<void> requestSubscription({
    required Plan plan,
    required String memberName,
    String paymentMethod = 'cash',
  }) async {
    final u = FirebaseAuth.instance.currentUser!;
    await _db.collection('subscriptions').add({
      'uid': u.uid,
      'memberName': memberName,
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

  /// تحميل الباقات لأول مرة (للأدمن فقط)
  static Future<void> seed() async {
    final batch = _db.batch();
    for (final p in _seedData()) {
      final id = p['id'] as String;
      final data = Map<String, dynamic>.from(p)..remove('id');
      batch.set(_db.collection('plans').doc(id), data);
    }
    await batch.commit();
  }

  // ---------- بيانات الأسعار (شاملة الضريبة) ----------
  static List<Map<String, dynamic>> _seedData() {
    final out = <Map<String, dynamic>>[];
    var order = 0;

    void months(String club, String group, String ar, String en,
        List<int> ms, List<num> prices) {
      for (var i = 0; i < ms.length; i++) {
        out.add({
          'id': '${club}_${group}_${ms[i]}m',
          'clubId': club,
          'groupKey': group,
          'groupAr': ar,
          'groupEn': en,
          'kind': 'months',
          'months': ms[i],
          'sessions': 0,
          'price': prices[i],
          'order': order++,
          'active': true,
        });
      }
    }

    void sessions(String club, String group, String ar, String en,
        List<int> sess, List<int> ms, List<num> prices) {
      for (var i = 0; i < sess.length; i++) {
        out.add({
          'id': '${club}_${group}_${sess[i]}s',
          'clubId': club,
          'groupKey': group,
          'groupAr': ar,
          'groupEn': en,
          'kind': 'sessions',
          'months': ms[i],
          'sessions': sess[i],
          'price': prices[i],
          'order': order++,
          'active': true,
        });
      }
    }

    void service(String club, String id, String titleAr, String titleEn,
        num price,
        {String noteAr = '', String noteEn = ''}) {
      out.add({
        'id': '${club}_svc_$id',
        'clubId': club,
        'groupKey': 'services',
        'groupAr': 'الخدمات الخاصة',
        'groupEn': 'Special services',
        'kind': 'service',
        'titleAr': titleAr,
        'titleEn': titleEn,
        'noteAr': noteAr,
        'noteEn': noteEn,
        'months': 0,
        'sessions': 0,
        'price': price,
        'order': order++,
        'active': true,
      });
    }

    void adultServices(String club, {required bool women}) {
      service(
        club,
        'inbody',
        'جلسة تحليل مكونات الجسم (InBody U300)',
        'Body composition analysis session (InBody U300)',
        115,
        noteAr: 'مجاناً قياس واحد شهرياً مع التدريب الشخصي',
        noteEn: 'One free measurement per month with personal training',
      );
      service(
        club,
        'program',
        'برنامج رياضي وغذائي خاص',
        'Custom sports & nutrition program',
        115,
        noteAr: 'مجاناً مع التدريب الشخصي',
        noteEn: 'Free with personal training',
      );
      service(
        club,
        'program_inbody',
        women
            ? 'برنامج رياضي + قياس InBody'
            : 'برنامج رياضي + قياس جهاز U300',
        women
            ? 'Sports program + InBody measurement'
            : 'Sports program + U300 measurement',
        184,
      );
    }

    // ---- الرجال ----
    months('men', 'gym_equip', 'باقة الأجهزة', 'Equipment plan',
        [1, 3, 6, 12], <num>[460, 1150, 1955, 3450]);
    months('men', 'gym_full', 'باقة الأجهزة والتدريبات الجماعية',
        'Equipment + group classes', [1, 3, 6, 12],
        <num>[575, 1552.5, 2484, 4222]);
    sessions('men', 'pt', 'التدريب الشخصي (رجال)', 'Personal training (men)',
        [14, 28, 42], [1, 2, 3], <num>[793.5, 1322.5, 1719.25]);
    adultServices('men', women: false);

    // ---- النساء ----
    months('women', 'gym_equip', 'باقة الأجهزة', 'Equipment plan',
        [1, 3, 6, 12], <num>[460, 1150, 1955, 3450]);
    months('women', 'gym_full', 'باقة الأجهزة والتدريبات الجماعية',
        'Equipment + group classes', [1, 3, 6, 12],
        <num>[575, 1380, 2300, 4140]);
    sessions('women', 'pt', 'التدريب الشخصي (سيدات)',
        'Personal training (women)', [12, 24, 36], [1, 2, 3],
        <num>[793.5, 1322.5, 1719.25]);
    adultServices('women', women: true);

    // ---- الصغار ----
    const km = [1, 2, 3, 6];
    months('kids', 'football', 'كرة القدم', 'Football', km,
        <num>[690, 1150, 1495, 2760]);
    months('kids', 'swimming', 'السباحة', 'Swimming', km,
        <num>[575, 920, 1150, 2070]);
    months('kids', 'karate', 'الكاراتيه', 'Karate', km,
        <num>[345, 575, 805, 1380]);
    months('kids', 'football_swim', 'كرة قدم + سباحة',
        'Football + Swimming', km, <num>[1150, 1955, 2530, 4600]);
    months('kids', 'football_karate', 'كرة قدم + كاراتيه',
        'Football + Karate', km, <num>[920, 1610, 2185, 3910]);
    months('kids', 'swim_karate', 'سباحة + كاراتيه', 'Swimming + Karate', km,
        <num>[805, 1495, 1840, 3220]);
    months('kids', 'all3', 'كرة قدم + كاراتيه + سباحة',
        'Football + Karate + Swimming', km, <num>[1495, 2645, 3335, 5980]);

    return out;
  }
}