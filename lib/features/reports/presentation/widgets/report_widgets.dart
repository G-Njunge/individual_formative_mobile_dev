import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/neu_surface.dart';
import '../../../../core/widgets/report_card.dart';
import '../../data/report.dart';

/// "2h ago". A report whose server timestamp hasn't arrived yet was made
/// moments ago on this phone.
String reportTimeLabel(Report r) =>
    TimeFormat.relative(r.createdAt ?? DateTime.now());

/// A column of report cards that open Report details when tapped.
class ReportCardList extends StatelessWidget {
  const ReportCardList({
    super.key,
    required this.reports,
    this.showMeToo = false,
  });

  final List<Report> reports;

  /// Browse shows "N me too" on each card; Home doesn't.
  final bool showMeToo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < reports.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.listGap),
          ReportCard(
            key: ValueKey(reports[i].id),
            category: reports[i].category,
            title: reports[i].title,
            place: reports[i].location,
            timeLabel: reportTimeLabel(reports[i]),
            status: reports[i].status,
            meTooCount: showMeToo ? reports[i].meTooCount : null,
            onTap: () => context.push(Routes.reportDetails(reports[i].id)),
          ),
        ],
      ],
    );
  }
}

/// "Spotted a problem?" card on Home: the paint background under a dark
/// overlay, with the only amber call to action on the screen.
class SpottedProblemCard extends StatelessWidget {
  const SpottedProblemCard({super.key, required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: NeuSurface.raisedShadows(c, NeuShadow.navBar),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/paint-bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: ColoredBox(
            color: c.heroOverlay,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spotted a problem?',
                    style: AppText.sectionHeading.copyWith(
                      fontSize: 19,
                      letterSpacing: -0.2,
                      color: c.onHero,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Snap a photo and report it in under a minute.',
                    style: AppText.body.copyWith(
                      fontSize: 13.5,
                      height: 1.45,
                      color: c.onHero.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 14),
                  NeuPressable(
                    onTap: onReport,
                    semanticLabel: 'Report an issue',
                    builder: (context, pressed) => AnimatedOpacity(
                      duration: AppDurations.fast,
                      opacity: pressed ? 0.85 : 1,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: c.amber,
                          borderRadius: BorderRadius.circular(
                            AppRadii.smallButton,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x59000000),
                              offset: Offset(0, 6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Align(
                          widthFactor: 1,
                          child: Text(
                            'Report an issue',
                            style: AppText.buttonSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: c.onAmber,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A photo attached on the New report form, with the amber remove button
/// overlapping its corner.
class AttachedPhotoTile extends StatelessWidget {
  const AttachedPhotoTile({
    super.key,
    required this.bytes,
    required this.index,
    required this.onRemove,
  });

  final Uint8List bytes;
  final int index;
  final VoidCallback onRemove;

  static const size = 110.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          NeuSurface(
            radius: 22,
            shadow: NeuShadow.button,
            width: size,
            height: size,
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
                semanticLabel: 'Attached photo ${index + 1}',
              ),
            ),
          ),
          Positioned(
            top: -14,
            right: -14,
            // 44 px touch target around the 28 px visible button.
            child: Semantics(
              button: true,
              label: 'Remove photo ${index + 1}',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '×',
                        style: AppText.buttonLarge.copyWith(
                          fontSize: 15,
                          height: 1,
                          color: c.onAmber,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pressed "+ Add photo" tile.
class AddPhotoTile extends StatelessWidget {
  const AddPhotoTile({super.key, required this.onTap, this.loading = false});

  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NeuPressable(
      onTap: onTap,
      semanticLabel: 'Add photo, up to ${AppConfig.maxPhotos}',
      builder: (context, pressed) => NeuSurface(
        depth: NeuDepth.pressed,
        shadow: pressed ? NeuShadow.insetMedium : NeuShadow.insetLarge,
        radius: 22,
        width: AttachedPhotoTile.size,
        height: AttachedPhotoTile.size,
        child: Center(
          child: loading
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: c.amberLight,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        color: c.amberLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add photo',
                      style: AppText.meta.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.amberLight,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
