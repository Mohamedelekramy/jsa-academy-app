import 'package:flutter/material.dart';

class ClubSection {
  final String key;
  final IconData icon;
  const ClubSection(this.key, this.icon);
}

class Club {
  final String id;
  final String nameKey;
  final String subKey;
  final Color color;
  final Color color2;
  final IconData icon;
  final String image; // صورة الكارت في الرئيسية
  final String banner; // صورة صفحة النادي
  final List<ClubSection> sections;

  const Club({
    required this.id,
    required this.nameKey,
    required this.subKey,
    required this.color,
    required this.color2,
    required this.icon,
    required this.image,
    required this.banner,
    required this.sections,
  });
}

const clubMen = Club(
  id: 'men',
  nameKey: 'clubMen',
  subKey: 'clubMenSub',
  color: Color(0xFF3A4A6B),
  color2: Color(0xFF111C36),
  icon: Icons.fitness_center_rounded,
  image: 'assets/images/club_men.jpg',
  banner: 'assets/images/banner_men.jpg',
  sections: [
    ClubSection('secFitness', Icons.directions_run_rounded),
    ClubSection('secIron', Icons.fitness_center_rounded),
    ClubSection('secPersonal', Icons.person_outline_rounded),
  ],
);

const clubKids = Club(
  id: 'kids',
  nameKey: 'clubKids',
  subKey: 'clubKidsSub',
  color: Color(0xFF2D8CFF),
  color2: Color(0xFF0B3C8C),
  icon: Icons.child_care_rounded,
  image: 'assets/images/club_kids.jpg',
  banner: 'assets/images/banner_kids.jpg',
  sections: [
    ClubSection('secSwim', Icons.pool_rounded),
    ClubSection('secKarate', Icons.sports_martial_arts_rounded),
    ClubSection('secFootball', Icons.sports_soccer_rounded),
  ],
);

const clubWomen = Club(
  id: 'women',
  nameKey: 'clubWomen',
  subKey: 'clubWomenSub',
  color: Color(0xFFB4408F),
  color2: Color(0xFF5A1B49),
  icon: Icons.female_rounded,
  image: 'assets/images/club_women.jpg',
  banner: 'assets/images/banner_women.jpg',
  sections: [
    ClubSection('secFitness', Icons.directions_run_rounded),
    ClubSection('secResistance', Icons.fitness_center_rounded),
    ClubSection('secGroup', Icons.groups_rounded),
    ClubSection('secSwim', Icons.pool_rounded),
    ClubSection('secCustom', Icons.tune_rounded),
  ],
);

const clubRehab = Club(
  id: 'rehab',
  nameKey: 'clubRehab',
  subKey: 'clubRehabSub',
  color: Color(0xFF1FA67A),
  color2: Color(0xFF0B4D3A),
  icon: Icons.healing_rounded,
  image: 'assets/images/club_rehab.jpg',
  banner: 'assets/images/banner_rehab.jpg',
  sections: [
    ClubSection('secRehabSports', Icons.accessibility_new_rounded),
    ClubSection('secInjuries', Icons.healing_rounded),
    ClubSection('secMotor', Icons.self_improvement_rounded),
    ClubSection('secRecovery', Icons.spa_outlined),
  ],
);

/// الترتيب هنا بيطابق التصميم (من اليمين للشمال بالعربي)
const List<Club> allClubs = [clubMen, clubKids, clubRehab, clubWomen];