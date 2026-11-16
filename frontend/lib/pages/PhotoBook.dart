import 'package:frontend/Widget/Polaroid.dart';
import 'package:frontend/Widget/ScrollableModal.dart';
import 'package:material_ui/material_ui.dart';
import 'package:turnable_page/turnable_page.dart';
import 'package:frontend/data/photo_repository.dart';

import 'dart:math';



class PhotoBook extends StatefulWidget {
  const PhotoBook( {super.key });
 
  @override
  State<PhotoBook> createState() => _PhotoBook();
  
}

class _PhotoBook extends State<PhotoBook> {
  static const _photosPerPage = 3;


  List<AlbumPhoto> _photosForPage(List<AlbumPhoto> all, int pageIndex) {
    final start = pageIndex * _photosPerPage;
    if (start >= all.length) return [];
    return all.sublist(start, min(start + _photosPerPage, all.length));
  }

  final _photosFuture = photoRepository.getPhotos();



  void _openModal(AlbumPhoto photo) {
  ScrollableModal.show(
    context,
    image: imageProviderFor(photo.imageUrl),
    title: photo.title,
    description: photo.description,
    date: MaterialLocalizations.of(context).formatMediumDate(photo.date),
  );
}
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Image.asset(
          'assets/images/temp_background.jpg',
          fit: BoxFit.cover,
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          }, 
          icon: Icon(Icons.arrow_back)
        ),
      ),


      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/temp_background.jpg"),
            fit: BoxFit.cover
          ),
        
        ),

        child:  FutureBuilder<List<AlbumPhoto>>(
  future: _photosFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      debugPrint('Load error: ${snapshot.error}');
      return const Center(child: Text('Could not load photos'));
    }
    final photos = snapshot.data!;
    if (photos.isEmpty) {
      return const Center(child: Text('No photos yet. Tap Upload!'));
    }

    return LayoutBuilder(
      builder: (context, box) => TurnablePage(
        pageCount: (photos.length / _photosPerPage).ceil(),
        pageViewMode: PageViewMode.auto,
        paperBoundaryDecoration: PaperBoundaryDecoration.none,
        aspectRatio: box.maxWidth / box.maxHeight,
        builder: (context, pageIndex, constraints) => AlbumPage(
          pageIndex: pageIndex,
          photos: _photosForPage(photos, pageIndex),
          onPhotoTap: _openModal,
        ),
      ),
    );
    },
  ),
),
);
  }
}



class _PageTemplate {
  const _PageTemplate({ required this.photos, required this.texts });

  final List<_Slot> photos;
  final List<_Slot> texts;
}

class _Slot {
  const _Slot(this.x, this.y, this.width, [this.angle=0]);

  final double x, y, width, angle;
}

const _photoSlots =  [
    _Slot(-0.7, -0.85, 0.40, -0.03),
    _Slot(0.65, -0.05, 0.40, 0.02),
    _Slot(-0.7, 0.85, 0.40, 0.03),
];

const _textSlots = [
    _Slot(0.75, -0.85, 0.38, 0),
    _Slot(-0.7, -0.05, 0.38, 0),
    _Slot(0.7, 0.85, 0.38, 0),
];

class AlbumPage extends StatelessWidget {
  const AlbumPage ({
    super.key,
    required this.pageIndex,
    required this.photos,
    required this.onPhotoTap,
  });

  final int pageIndex;
  final List<AlbumPhoto> photos;
  final void Function(AlbumPhoto photo) onPhotoTap;
  

  @override
  Widget build(BuildContext context) {
    final isLeft = pageIndex.isEven;
    final flip = isLeft ? 1.0 : -1.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            Color(0xFFF4F3EF),
            Color(0xFFF4F3EF),
            Color(0xFFD6D5D0),
          ],
          stops: [0, 0.85, 1],
        ),
      ),

      padding: EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, box) {
          final unit = min(box.maxWidth, box.maxHeight * 0.55);

          Widget place(_Slot s, Widget child) => Align(
            alignment: Alignment(s.x * flip, s.y),
            child: Transform.rotate(
              angle: s.angle * flip,
              child: SizedBox(width: unit * s.width, child: child,),
            ),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < photos.length; i++) 
                place(
                    _textSlots[i],
                    Image.asset(
                      // Same seed = same scribble every time this page is built
                      'assets/images/random_scribbles/random_scribble_${Random(pageIndex * 10 + i).nextInt(6) + 1}.png',
                      fit: BoxFit.contain,
                    ),
                  ),
      
              
              for (var i = 0; i < photos.length; i++) 
               place(
                _photoSlots[i],
                GestureDetector(
                  onTap: () => onPhotoTap(photos[i]),
                  child: Polaroid(imageUrl: photos[i].imageUrl),
                ),
              ),
              
            ],
          );
        }
      ),
    );
  }
}

