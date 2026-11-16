import 'package:material_ui/material_ui.dart';
import 'package:frontend/data/photo_repository.dart';

class Polaroid extends StatelessWidget {
  const Polaroid( {super.key, required this.imageUrl} );


  final String imageUrl;
  static const _asset = 'assets/images/polaroid.png';

  static const _imageW = 500.0, _imageH = 627.0;
  static const _left = 24.0, _top = 30.0, _right = 462.0, _bottom = 487.0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _imageW / _imageH,
      child: LayoutBuilder(
        builder: (context, box) {
          final sx = box.maxWidth / _imageW;
          final sy = box.maxHeight / _imageH;


          return Stack(
            children: [
              Positioned(
                left: _left * sx,
                top: _top * sy,
                width: (_right - _left) * sx,
                height: (_bottom - _top) * sy,
                child: Image(
                  image: imageProviderFor(imageUrl), 
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade400,
                    child: const Icon(Icons.broken_image),
                  ),  
                ),
              ),

              Positioned.fill(
                child: Image.asset(_asset, fit: BoxFit.fill),
              ),
            ],
          );
        }
      )
    );
  }
  
}