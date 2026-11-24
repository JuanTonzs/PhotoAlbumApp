import 'package:frontend/Widget/Polaroid.dart';
import 'package:frontend/config.dart';
import 'package:frontend/data/letter_items.dart';
import 'package:material_ui/material_ui.dart';


class LetterPaper extends StatefulWidget {
  const LetterPaper({
    super.key,
    required this.paperColor,
    required this.text,
    required this.items,
    this.placeholder = '',
    this.editable = false,
    this.selected,
    this.onSelect,
    this.drawing = false,
    this.penColor = 0xFF222222,
  });


  final Color paperColor;
  final String text;
  final List<LetterItem> items;
  final String placeholder;
  final bool editable;
  final LetterItem? selected;
  final ValueChanged<LetterItem?>? onSelect;
  final bool drawing;
  final int penColor;

  @override
  State<LetterPaper> createState() => _LetterPaper();
}


class _LetterPaper extends State<LetterPaper> {
  double _startScale = 1;
  double _startRotation = 0;

  TextStyle _textStyle(double w, Color color) =>
    TextStyle(color: color, fontSize: w * 0.05, height: 1.35);

  Offset _norm(Offset p, double w, double h) => Offset(
    (p.dx / w).clamp(0.0, 1.0).toDouble(),
    (p.dy / h).clamp(0.0, 1.0).toDouble(),
  );


  void _strokeStart(Offset p, double w, double h) {
    setState(() {
      widget.items.add(LetterItem(
        type: 'stroke',
        color: widget.penColor,
        points: [_norm(p, w, h)] 

      ));
    });
  }



  void _strokeMove(Offset p, double w, double h) {
    if (widget.items.isEmpty || widget.items.last.type != 'stroke') return;

    final stroke = widget.items.last;
    final n = _norm(p, w, h);
    if ((stroke.points.last - n).distance < 0.004) return;
    setState(() => stroke.points.add(n));
  }


  Widget _buildItem(LetterItem item, double w, double h) {
    if (item.type == 'stroke') {
      return Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _StrokePainter(item),),),
      );
    }


    final isPhoto = item.type == 'photo';
    final size = w * (isPhoto ? 0.42 : 0.26) * item.scale;

    Widget content = SizedBox(
      width: size,
      child: isPhoto
        ? Polaroid(imageUrl: '${Config.apiBase}/photos/${item.photoId}/image')
        : StickerImage(name: item.asset ?? '', width: size),
    );

    if (widget.editable && identical(item, widget.selected)) {
      content = DecoratedBox( 
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: Border.all(color: Colors.black54, width: 2)),
        child: content,
      );
    }


    if (widget.editable && !widget.drawing) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (_) {
          _startScale = item.scale;
          _startRotation = item.rotation;
          widget.onSelect?.call(item);
        },

        onScaleUpdate: (d) {
          setState(() {
            item.x = (item.x + d.focalPointDelta.dx / w).clamp(0.0, 1.0).toDouble();
            item.y = (item.y + d.focalPointDelta.dy / h).clamp(0.0, 1.0).toDouble();
            item.scale = (_startScale * d.scale).clamp(0.3, 4.0).toDouble();
            item.rotation = _startRotation + d.rotation;
          });
        },
        child: content,
      );
    }



    return Positioned(
      left: item.x * w,
      top: item.y * h,
      child: FractionalTranslation(
        translation: Offset(-0.5, -0.5),
        child: Transform.rotate(angle: item.rotation, child: content),

      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    
    return Center(
      child: AspectRatio(
        aspectRatio: kPaperAspect,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;

            return Container(
              decoration: BoxDecoration(
                color: widget.paperColor,
                border: Border.all(color: Colors.black26),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(3, 3)),

                ],
              ),
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.editable ? () => widget.onSelect?.call(null) : null,
                        child: Padding(
                          padding: EdgeInsets.all(w * 0.07),
                          child: widget.text.isEmpty
                            ? Text(widget.placeholder,
                              style: _textStyle(w, Colors.black38),)
                            : Text(widget.text, style: _textStyle(w, Colors.black87),),
                        ),
                      ),
                    ),

                    for (final item in widget.items) _buildItem(item, w, h),

                    if (widget.drawing)
                      Positioned.fill(
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (e) => _strokeStart(e.localPosition, w, h),
                          onPointerMove: (e) => _strokeMove(e.localPosition, w, h),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


class StickerImage extends StatelessWidget {
  const StickerImage({super.key, required this.name, required this.width});

  final String name;
  final double width;


  @override
  Widget build(BuildContext context) {
    return Image.asset(
      stickerPath(name),
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: width,
        child: Icon(Icons.local_florist, size: width * 0.6, color: Colors.grey),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.item);

  final LetterItem item;

  @override
  void paint(Canvas canvas, Size size) {
    if (item.points.isEmpty) return;

    final paint = Paint()
      ..color = Color(item.color)
      ..strokeWidth = item.width * size.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    
    Offset at(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    if (item.points.length == 1) {
      canvas.drawCircle(
        at(item.points.first),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );

      return;
    }


    final first = at(item.points.first);
    final path = Path()..moveTo(first.dx, first.dy);
    for (final p in item.points.skip(1)) {
      final o = at(p);
      path.lineTo(o.dx, o.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
    
}