import 'package:cloud_firestore/cloud_firestore.dart';

const announcementTypes = ['news', 'offer', 'tournament'];

class Announcement {
  final String id;
  final String type;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.createdAt,
  });

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    String s(String k) => (m[k] ?? '').toString();
    final ts = m['createdAt'];
    return Announcement(
      id: d.id,
      type: s('type').isEmpty ? 'news' : s('type'),
      titleAr: s('titleAr'),
      titleEn: s('titleEn'),
      bodyAr: s('bodyAr'),
      bodyEn: s('bodyEn'),
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  String title(String lang) {
    final first = lang == 'en' ? titleEn : titleAr;
    final second = lang == 'en' ? titleAr : titleEn;
    return first.isNotEmpty ? first : second;
  }

  String body(String lang) {
    final first = lang == 'en' ? bodyEn : bodyAr;
    final second = lang == 'en' ? bodyAr : bodyEn;
    return first.isNotEmpty ? first : second;
  }
}

class AnnouncementService {
  static final CollectionReference<Map<String, dynamic>> _col =
  FirebaseFirestore.instance.collection('announcements');

  static Stream<List<Announcement>> stream() {
    return _col.snapshots().map((s) {
      final l = s.docs.map(Announcement.fromDoc).toList();
      l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return l;
    });
  }

  static Future<void> add(Map<String, String> data) {
    return _col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
  }

  static Future<void> update(String id, Map<String, String> data) {
    return _col.doc(id).update(data);
  }

  static Future<void> delete(String id) => _col.doc(id).delete();
}