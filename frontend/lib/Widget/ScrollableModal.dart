 // REFERENCE FOR THE MODAL https://medium.com/@crystalize0106/custom-draggable-modal-bottom-sheet-in-flutter-7139429c1442
 
 
 import 'package:material_ui/material_ui.dart';
 

class ScrollableModal extends StatelessWidget {
  const ScrollableModal({ 
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.date,
    required this.onEdit,
    required this.onDelete,
  });

  final ImageProvider image;
  final String title;
  final String description;
  final String date;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static Future<void> show(
    BuildContext context, {
      required ImageProvider image,
      required String title,
      required String description,
      required String date,
      required VoidCallback onEdit,
      required VoidCallback onDelete,
    }
  ) {
    return showModalBottomSheet<void>(
      context: context, 
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => ScrollableModal(
        image: image,
        title: title,
        description: description,
        date: date,
        onEdit: onEdit,
        onDelete: onDelete,
      )
    );
  }


  @override
  Widget build(BuildContext context) {    
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          margin: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
          ),



          child: ListView(
            controller: controller,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _DragHandle(),
              SizedBox(height: 8,),
              Image(
                image: image,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16,),

              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Omori'
                ),
              ),


              const SizedBox(height: 16,),

              Text(
                date,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontFamily: 'Omori'
                ),
              ),


              const SizedBox(height: 16,),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontFamily: 'Omori'
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Edit photo',
                    onPressed: () {
                      Navigator.pop(context); // close the sheet
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white54),
                  ),
                  IconButton(
                    tooltip: 'Delete photo',
                    onPressed: () {
                      Navigator.pop(context); // close the sheet
                      onDelete();
                    },
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
}


class _DragHandle extends StatelessWidget {
  const _DragHandle();


  @override
  Widget build(BuildContext context) {

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 30,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white
        ),
      )
    );
  }
}