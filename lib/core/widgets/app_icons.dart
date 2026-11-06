import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The design's line icons, copied from the templates so they match exactly.
/// Each is a 24×24 stroke icon; colour and stroke width are filled in at
/// render time.
enum AppIcon {
  home('<path d="M3 11l9-7 9 7v8a2 2 0 0 1-2 2h-4v-6h-6v6H5a2 2 0 0 1-2-2Z"/>'),
  reports(
    '<rect x="5" y="3" width="14" height="18" rx="3"/><path d="M9 8h6M9 12h6M9 16h3"/>',
  ),
  plus('<path d="M12 5v14M5 12h14"/>'),
  bell(
    '<path d="M6 9a6 6 0 0 1 12 0c0 6 2.5 7.5 2.5 7.5h-17S6 15 6 9Z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
  ),
  profile(
    '<circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/>',
  ),
  dashboard(
    '<rect x="4" y="4" width="7" height="7" rx="2"/><rect x="13" y="4" width="7" height="7" rx="2"/><rect x="4" y="13" width="7" height="7" rx="2"/><rect x="13" y="13" width="7" height="7" rx="2"/>',
  ),
  search('<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/>'),
  back('<path d="M15 6l-6 6 6 6"/>'),
  close('<path d="M6 6l12 12M18 6L6 18"/>'),
  check('<path d="M5 12l5 5 9-10"/>'),
  chevronRight('<path d="M9 6l6 6-6 6"/>');

  const AppIcon(this.paths);

  final String paths;
}

class AppIconView extends StatelessWidget {
  const AppIconView(
    this.icon, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth = 2,
  });

  final AppIcon icon;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="$hex" stroke-opacity="${color.a}" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">${icon.paths}</svg>';
    // Icons are decorative; the button around them carries the label.
    return ExcludeSemantics(
      child: SvgPicture.string(svg, width: size, height: size),
    );
  }
}
