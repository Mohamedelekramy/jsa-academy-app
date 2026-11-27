import 'package:cloud_firestore/cloud_firestore.dart';

/// سطر في الجدول: مدرب في قسم بموعد، أو مرفق (ملعب مثلاً)
class ScheduleItem {
  final String id;
  final String clubId;
  final String sectionKey;
  final String sectionAr;
  final String sectionEn;
  final String groupAr;
  final String groupEn;
  final String trainerAr;
  final String trainerEn;
  final String kind; // trainer | facility
  final int startMin; // دقائق من منتصف الليل
  final int endMin;
  final int order;
  final bool active;

  const ScheduleItem({
    required this.id,
    required this.clubId,
    required this.sectionKey,
    required this.sectionAr,
    required this.sectionEn,
    required this.groupAr,
    required this.groupEn,
    required this.trainerAr,
    required this.trainerEn,
    required this.kind,
    required this.startMin,
    required this.endMin,
    required this.order,
    required this.active,
  });

  factory ScheduleItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return ScheduleItem(
      id: d.id,
      clubId: (m['clubId'] ?? '') as String,
      sectionKey: (m['sectionKey'] ?? '') as String,
      sectionAr: (m['sectionAr'] ?? '') as String,
      sectionEn: (m['sectionEn'] ?? '') as String,
      groupAr: (m['groupAr'] ?? '') as String,
      groupEn: (m['groupEn'] ?? '') as String,
      trainerAr: (m['trainerAr'] ?? '') as String,
      trainerEn: (m['trainerEn'] ?? '') as String,
      kind: (m['kind'] ?? 'trainer') as String,
      startMin: (m['startMin'] as num?)?.toInt() ?? -1,
      endMin: (m['endMin'] as num?)?.toInt() ?? -1,
      order: (m['order'] as num?)?.toInt() ?? 0,
      active: (m['active'] ?? true) as bool,
    );
  }

  String section(bool ar) => ar ? sectionAr : sectionEn;
  String group(bool ar) => ar ? groupAr : groupEn;
  String trainer(bool ar) => ar ? trainerAr : trainerEn;
  bool get isFacility => kind == 'facility';

  bool openAt(int nowMin) =>
      !isFacility && startMin >= 0 && nowMin >= startMin && nowMin < endMin;
}

class ScheduleService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<List<ScheduleItem>> byClub(String clubId) {
    return _db
        .collection('schedules')
        .where('clubId', isEqualTo: clubId)
        .snapshots()
        .map((s) {
      final list =
      s.docs.map(ScheduleItem.fromDoc).where((i) => i.active).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  /// تحميل الجدول لأول مرة (للأدمن فقط)
  static Future<void> seed() async {
    final batch = _db.batch();
    for (final p in _seedData()) {
      final id = p['id'] as String;
      final data = Map<String, dynamic>.from(p)..remove('id');
      batch.set(_db.collection('schedules').doc(id), data);
    }
    await batch.commit();
  }

  // ---------- بيانات الجدول (من ورقة المدير) ----------
  static List<Map<String, dynamic>> _seedData() {
    final out = <Map<String, dynamic>>[];
    var order = 0;

    String slug(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    int hm(int h, [int m = 0]) => h * 60 + m;

    void trainer(
        String club,
        String sec,
        String secAr,
        String secEn,
        String tAr,
        String tEn,
        int s,
        int e, {
          String gAr = '',
          String gEn = '',
        }) {
      out.add({
        'id': '${club}_${sec}_${slug(tEn)}_${slug(gEn)}',
        'clubId': club,
        'sectionKey': sec,
        'sectionAr': secAr,
        'sectionEn': secEn,
        'groupAr': gAr,
        'groupEn': gEn,
        'trainerAr': tAr,
        'trainerEn': tEn,
        'startMin': s,
        'endMin': e,
        'kind': 'trainer',
        'order': order++,
        'active': true,
      });
    }

    void facility(String club, String sec, String secAr, String secEn,
        String nAr, String nEn) {
      out.add({
        'id': '${club}_${sec}_${slug(nEn)}',
        'clubId': club,
        'sectionKey': sec,
        'sectionAr': secAr,
        'sectionEn': secEn,
        'groupAr': nAr,
        'groupEn': nEn,
        'trainerAr': '',
        'trainerEn': '',
        'startMin': -1,
        'endMin': -1,
        'kind': 'facility',
        'order': order++,
        'active': true,
      });
    }

    // ---- الرجال ----
    const fitAr = 'صالة اللياقة البدنية';
    const fitEn = 'Fitness hall';
    trainer('men', 'gym_fitness', fitAr, fitEn, 'رشيد مالك', 'Rashid Malik',
        hm(8), hm(16));
    trainer('men', 'gym_fitness', fitAr, fitEn, 'إيهاب الشندويلي',
        'Ehab Al-Shandweely', hm(13), hm(21));

    const ironAr = 'صالة الحديد';
    const ironEn = 'Iron hall';
    trainer('men', 'gym_iron', ironAr, ironEn, 'إسلام', 'Islam', hm(16), hm(24));

    const ptAr = 'التدريب الشخصي';
    const ptEn = 'Personal training';
    trainer('men', 'pt', ptAr, ptEn, 'رشيد مالك', 'Rashid Malik', hm(8), hm(16));
    trainer('men', 'pt', ptAr, ptEn, 'إيهاب الشندويلي', 'Ehab Al-Shandweely',
        hm(13), hm(21));
    trainer('men', 'pt', ptAr, ptEn, 'إسلام', 'Islam', hm(16), hm(24));

    const exAr = 'إضافات ترفيهية';
    const exEn = 'Entertainment extras';
    facility('men', 'extras', exAr, exEn, 'ملعب كرة قدم', 'Football pitch');
    facility('men', 'extras', exAr, exEn, 'كرة طائرة رملية', 'Beach volleyball');
    facility('men', 'extras', exAr, exEn, 'جري خارجي', 'Outdoor running');

    // ---- الصغار: كرة القدم ----
    const fbAr = 'كرة القدم';
    const fbEn = 'Football';
    trainer('kids', 'kids_football', fbAr, fbEn, 'بيبيو', 'Bebo', hm(14),
        hm(22),
        gAr: 'فئة A (6 إلى 9 سنوات)', gEn: 'Category A (6-9 years)');
    trainer('kids', 'kids_football', fbAr, fbEn, 'عماد زينهم', 'Emad Zeinhom',
        hm(14), hm(22),
        gAr: 'فئة B (10 إلى 13 سنة)', gEn: 'Category B (10-13 years)');
    trainer('kids', 'kids_football', fbAr, fbEn, 'أحمد خطاب', 'Ahmed Khattab',
        hm(15), hm(23),
        gAr: 'فئة C (14 إلى 16 سنة)', gEn: 'Category C (14-16 years)');

    // ---- الصغار: السباحة ----
    const swAr = 'السباحة';
    const swEn = 'Swimming';
    trainer('kids', 'kids_swim', swAr, swEn, 'إسلام عبد العزيز',
        'Islam Abdelaziz', hm(14), hm(22),
        gAr: 'بنين - تعليمي', gEn: 'Boys - Learning');
    trainer('kids', 'kids_swim', swAr, swEn, 'وائل القليوبي',
        'Wael Al-Qaliubi', hm(14), hm(22),
        gAr: 'بنين - ممارس', gEn: 'Boys - Practice');
    trainer('kids', 'kids_swim', swAr, swEn, 'فاطمة', 'Fatima', hm(13), hm(21),
        gAr: 'بنات - تعليمي', gEn: 'Girls - Learning');
    trainer('kids', 'kids_swim', swAr, swEn, 'يارا عماد', 'Yara Emad',
        hm(14), hm(22),
        gAr: 'بنات - ممارس', gEn: 'Girls - Practice');

    // ---- الصغار: الكاراتيه ----
    const kaAr = 'الكاراتيه';
    const kaEn = 'Karate';
    trainer('kids', 'kids_karate', kaAr, kaEn, 'مصطفى شعبان',
        'Mostafa Shaaban', hm(15), hm(23),
        gAr: 'تعليمي (بنين وبنات)', gEn: 'Learning (boys & girls)');
    trainer('kids', 'kids_karate', kaAr, kaEn, 'مصطفى شعبان',
        'Mostafa Shaaban', hm(15), hm(23),
        gAr: 'ممارس (بنين وبنات)', gEn: 'Practice (boys & girls)');

    return out;
  }
}