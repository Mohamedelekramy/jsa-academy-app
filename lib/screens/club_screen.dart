import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/clubs.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/soon.dart';

class ClubScreen extends StatelessWidget {
  final Club club;
  const ClubScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                child: Row(
                  children: [
                    const BackButton(),
                    Expanded(
                      child: Text(
                        context.tr(club.nameKey),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(club.icon, color: AppColors.goldLight),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // الغلاف
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [club.color, club.color2],
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              top: -10,
                              end: -10,
                              child: Icon(
                                club.icon,
                                size: 170,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            Image.asset(
                              club.banner,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.4, 1],
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Align(
                                alignment: AlignmentDirectional.bottomStart,
                                child: Text(
                                  context.tr(club.subKey),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // الأقسام
                    GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final s in club.sections)
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => showSoon(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.glass,
                                borderRadius: BorderRadius.circular(18),
                                border:
                                Border.all(color: AppColors.glassBorder),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(s.icon,
                                      size: 30, color: AppColors.goldLight),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr(s.key),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: const TextStyle(
                                        fontSize: 12, height: 1.25),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GoldButton(
                      text: context.tr('subscribeNow'),
                      onTap: () => showSoon(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}