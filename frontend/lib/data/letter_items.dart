import 'package:material_ui/material_ui.dart';

const kPaperAspect = 0.72;
const kMaxLettersChars = 500;


// File names (without .png)  sticker drawings in assets/images/stickers/
// Replace these with your real files.
// Temp files
const kStickers = ['sticker_1', 'sticker_2', 'sticker_3'];

String stickerPath(String name) => 'assets/images/strickers/$name.png';

const kPenColors = [
  0xFF222222,
  0xFFE0607E,
  0xFF29A8F0,
  0xFF9BD93C,
  0xFFF2B632,
  0xFF8E5BD9,
];

double _r(double v) => double.parse(v.toStringAsFixed(4));


class LetterItem {
  LetterItem({
    required this.type,
    this.asset,
    this.photoId,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = 0xFF222222,
    this.width = 0.012,
    List<Offset>? points,
  }) : points = points ?? [];

  final String type;
  final String? asset;
  final String? photoId;
  double x, y, scale, rotation;
  final int color;
  final double width;
  final List<Offset> points;

  Map<String, dynamic> toJson() {
    if (type == 'stroke') {
      return {
        'type': 'stroke',
        'color': color,
        'width': width,
        'points': [
          for (final p in points) [_r(p.dx), _r(p.dy)],
        ],
      };
    }

    return {
      'type': type,
      if (asset != null) 'asset': asset,
      if (photoId != null) 'photoId': photoId,
      'x': _r(x),
      'y': _r(y),
      'scale': _r(scale),
      'rotation': _r(rotation),
    };
  }


  factory LetterItem.fromJson(Map<String, dynamic> j) => LetterItem(
    type: j['type'] as String,
    asset: j['asset'] as String?,
    photoId: j['photoId'] as String?,
    x: (j['x'] as num?)?.toDouble() ?? 0.5,
    y: (j['y'] as num?)?.toDouble() ?? 0.5,
    scale: (j['scale'] as num?)?.toDouble() ?? 1.0,
    rotation: (j['rotation'] as num?)?.toDouble() ?? 0.0,
    color: (j['color'] as num?)?.toInt() ?? 0xFF2222222,
    width: (j['width'] as num?)?.toDouble() ?? 0.012,
    points: [
      for (final p in (j['points'] as List? ?? const []))
        Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ]

  );
}