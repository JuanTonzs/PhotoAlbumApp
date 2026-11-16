

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';


class UploadPhotos extends StatefulWidget {
    const UploadPhotos( {super.key });


    @override
  State<UploadPhotos> createState() => _UploadPhotos();
}

class _UploadPhotos extends State<UploadPhotos> {
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  File? _image;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if(pickedFile != null) {
      _image = File(pickedFile.path);
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, 
      firstDate: DateTime(1990),
      lastDate: DateTime.now()
    );

    if(picked == null) return;

    setState(() => _date = picked);
  }

  void _save() {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select a photo!"),)
      );
    }

    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();

    debugPrint('Saving ${_image!.path} | $description | $_date');

    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    final dateText = MaterialLocalizations.of(context).formatMediumDate(_date);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          }, 
          icon: Icon(Icons.arrow_back)
        ),
        
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_image == null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text("No Image"),),
                )
              
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: Image.file(_image!, fit: BoxFit.contain,),
                ),

              SizedBox(height: 24,),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: 'Description of Image',),

                validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Add a short description'
                  : null,
              ),

              SizedBox(height: 16,),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),

                  child: Text(dateText),
                
                ),
              ),

              SizedBox(height: 24,),
              ElevatedButton(
                onPressed: _save, 
                child: Text('Save'),
              )
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add, color: Colors.white,),
      ),
    );
  }
}