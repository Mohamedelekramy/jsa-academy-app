import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// صورة المستخدم (من Base64) أو أيقونة افتراضية
class UserAvatar extends StatelessWidget {
  final String? photoB64;
  final double radius;
  const UserAvatar({super.key, this.photoB64, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    try {
      if (photoB64 != null && photoB64!.isNotEmpty) {
        img = MemoryImage(base64Decode(photoB64!));
      }
    } catch (_) {}

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navyLight,
      backgroundImage: img,
      child: img == null
          ? Icon(Icons.person_rounded, color: Colors.white, size: radius)
          : null,
    );
  }
}