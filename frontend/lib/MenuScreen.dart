import 'package:frontend/pages/DrawMusic.dart';
import 'package:frontend/pages/PhotoBook.dart';
import 'package:frontend/pages/UploadPhotos.dart';
import 'package:material_ui/material_ui.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen( {super.key });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/test_bg.gif"),
            fit: BoxFit.cover,
          )
        ),    
        
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 0,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MenuButton(
              asset: 'assets/images/start_button.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhotoBook()),
              ),
            ),
            _MenuButton(
              asset: 'assets/images/upload_button.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadPhotos()),
              ),
            ),
            _MenuButton(
              asset: 'assets/images/blank_button.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DrawMusic()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.7;
  

    return GestureDetector(
      onTap: onTap,
      child: Image.asset(asset, width: width, fit: BoxFit.fitWidth,),
    );
  }
}