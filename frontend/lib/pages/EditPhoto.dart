import 'package:frontend/data/photo_repository.dart';
import 'package:material_ui/material_ui.dart';

class EditPhoto extends StatefulWidget {
  const EditPhoto({super.key, required this.photo});

  final AlbumPhoto photo;

  @override
  State<EditPhoto> createState() => _EditPhoto();
}

class _EditPhoto extends State<EditPhoto> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.photo.title);
  late final _descriptionController =
      TextEditingController(text: widget.photo.description);
  late DateTime _date = widget.photo.date;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await photoRepository.updatePhoto(
        id: widget.photo.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _date,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Update error: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save changes. Check your connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = MaterialLocalizations.of(context).formatMediumDate(_date);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image(
                  image: imageProviderFor(widget.photo.imageUrl),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Description of Image'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Add a short description'
                    : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateText),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}