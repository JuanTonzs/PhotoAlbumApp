import 'package:frontend/Widget/ScrollableModal.dart';
import 'package:material_ui/material_ui.dart';
import 'package:turnable_page/turnable_page.dart';
import 'dart:math';

class AlbumPhoto {
  const AlbumPhoto( {required this.imageUrl, required this.description} );

  final String imageUrl;
  final String description;
}


class PhotoBook extends StatefulWidget {
  const PhotoBook( {super.key });
 
  @override
  State<PhotoBook> createState() => _PhotoBook();
  
}

class _PhotoBook extends State<PhotoBook> {
  static const _photosPerPage = 3;



    // TODO: TEMP, THIS WILL BE IMAGES FROM LIKE A DATABASE OR SMTH
  final List<AlbumPhoto> photoArray = [
    AlbumPhoto(
      imageUrl: 'https://images.pexels.com/photos/17259379/pexels-photo-17259379.jpeg',
      description: 'A beautiful landscape',
      ),
    AlbumPhoto(
      imageUrl: 'https://images.pexels.com/photos/17259379/pexels-photo-17259379.jpeg',
      description: 'A beautiful landscape',
      ),
  ];

  int get _pageCount => (photoArray.length / _photosPerPage).ceil();


  List<AlbumPhoto> _photosForPage(int pageIndex) {
    final start = pageIndex * _photosPerPage;
    if (start >= photoArray.length) return [];
    final end = min(start + _photosPerPage, photoArray.length);
    return photoArray.sublist(start, end);
  }

  void _openModal(AlbumPhoto photo) {
    ScrollableModal.show(
      context,
      image: NetworkImage(photo.imageUrl),
      description: photo.description
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

        child: LayoutBuilder(
          builder: (content, box) => TurnablePage(
            pageCount: _pageCount, // Change to be more dynamic
            pageViewMode: PageViewMode.auto,
            paperBoundaryDecoration: PaperBoundaryDecoration.none,
            aspectRatio: box.maxWidth / box.maxHeight,
            builder: (context, pageIndex, constraints) => AlbumPage(
              pageIndex: pageIndex,
              photos: _photosForPage(pageIndex),
              onPhotoTap: _openModal,
            ),
          ),
        
        )

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
          final unit = min(box.maxWidth, box.maxHeight / 1.4);

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
                Align(
                  alignment: Alignment(_textSlots[i].x * flip, _textSlots[i].y),
                  child: Transform.rotate(
                    angle: _textSlots[i].angle * flip,
                    child: SizedBox(
                      width: unit * _textSlots[i].width,
                      child: Image.asset(
                        'assets/images/random_scribbles/random_scribble_${Random().nextInt(6) + 1}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              
              for (var i = 0; i < photos.length; i++) 
                Align(
                  alignment: Alignment(_photoSlots[i].x * flip, _photoSlots[i].y),
                  child: Transform.rotate(
                    angle: _photoSlots[i].angle * flip,
                    child: GestureDetector(
                      onTap: () => onPhotoTap(photos[i]),
                      child: SizedBox(
                        width: unit * _photoSlots[i].width,
                        child: AspectRatio(
                          aspectRatio: 0.82,
                          child: Image.network(
                            photos[i].imageUrl,
                            fit:BoxFit.cover
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              
            ],
          );
        }
      ),
    );
  }
}

