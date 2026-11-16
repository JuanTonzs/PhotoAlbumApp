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
            image: AssetImage("assets/images/temp_background.jpg"),
            fit: BoxFit.cover,
          )
        ),    
        
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 0,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // Moves to the next page
                // Recently .push adds to scene, .pop removes (ie goes back to prev screen)
                Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoBook()));
              },
              child: Image.asset(
                'assets/images/start_button.png',
                width: 400,
                height: 400,
                fit: BoxFit.contain
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UploadPhotos()));
              },
              child: Image.asset(
                'assets/images/upload_button.png',
                width: 225,
                height: 225,
                fit: BoxFit.contain
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}