import 'package:frontend/Widget/LetterPaper.dart';
import 'package:frontend/data/letter_items.dart';
import 'package:frontend/data/letter_repository.dart';
import 'package:frontend/data/photo_repository.dart';
import 'package:material_ui/material_ui.dart';

class ComposeLetter extends StatefulWidget {
  const ComposeLetter({super.key, required this.from});

  final Who from;

  @override
  State<ComposeLetter> createState() => _ComposeLetter();
}

class _ComposeLetter extends State<ComposeLetter> {
  final _textController = TextEditingController();
  final List<LetterItem> _items = [];
  String _text = '';
  LetterItem? _selected;
  bool _drawing = false;
  int _pen = kPenColors[0];
  bool _sending = false;

  static const _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
    side: BorderSide(color: Colors.white, width: 2),
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ---- Actions ---------------------------------------------------------------

  Future<void> _editText() async {
    _textController.text = _text;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: _sheetShape,
        title: Text('Dear ${widget.from.other.label},'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          minLines: 4,
          maxLines: 8,
          maxLength: kMaxLettersChars,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _textController.text),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _text = result.trim());
  }

  Future<void> _addSticker() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black,
      shape: _sheetShape,
      builder: (context) => GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final name in kStickers)
            GestureDetector(
              onTap: () => Navigator.pop(context, name),
              child: StickerImage(name: name, width: 80),
            ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    _addItem(LetterItem(type: 'sticker', asset: name));
  }

  Future<void> _addPhoto() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: _sheetShape,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: FutureBuilder<List<AlbumPhoto>>(
          future: photoRepository.getPhotos(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return const Center(child: Text('Could not load your photos'));
            }
            final photos = snap.data!;
            if (photos.isEmpty) {
              return const Center(child: Text('No photos in the album yet'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: photos.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.pop(context, photos[i].id),
                child: Image(
                  image: imageProviderFor(photos[i].imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
    if (id == null || !mounted) return;
    _addItem(LetterItem(type: 'photo', photoId: id));
  }

  void _addItem(LetterItem item) {
    setState(() {
      _items.add(item);
      _selected = item;
      _drawing = false;
    });
  }

  void _undo() {
    if (_items.isEmpty) return;
    setState(() {
      final removed = _items.removeLast();
      if (identical(removed, _selected)) _selected = null;
    });
  }

  void _deleteSelected() {
    final s = _selected;
    if (s == null) return;
    setState(() {
      _items.remove(s);
      _selected = null;
    });
  }

  Future<void> _send() async {
    if (_text.isEmpty && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write or decorate something first!')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await letterRepository.send(_text, _items);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Send error: $e');
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send. Check your connection.')),
      );
    }
  }

  // ---- UI ----------------------------------------------------------------------

  BoxDecoration get _barDecoration => BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white, width: 2),
      );

  Widget _penRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: _barDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final c in kPenColors)
            GestureDetector(
              onTap: () => setState(() => _pen = c),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(c),
                  border: Border.all(
                    color: _pen == c ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: _barDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Write',
            onPressed: _editText,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Stickers',
            onPressed: _addSticker,
            icon: const Icon(Icons.emoji_emotions_outlined),
          ),
          IconButton(
            tooltip: 'Photos',
            onPressed: _addPhoto,
            icon: const Icon(Icons.photo_outlined),
          ),
          IconButton(
            tooltip: 'Draw',
            onPressed: () => setState(() {
              _drawing = !_drawing;
              _selected = null;
            }),
            icon: Icon(
              Icons.brush,
              color: _drawing ? widget.from.envelope : null,
            ),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: _items.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Delete selected',
            onPressed: _selected == null ? null : _deleteSelected,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('To ${widget.from.other.label}'),
        actions: [
          IconButton(
            tooltip: 'Send',
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/temp_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LetterPaper(
                    paperColor: widget.from.paper,
                    text: _text,
                    placeholder: 'Tap the pen below to write your letter',
                    items: _items,
                    editable: true,
                    selected: _selected,
                    onSelect: (item) => setState(() => _selected = item),
                    drawing: _drawing,
                    penColor: _pen,
                  ),
                ),
              ),
              if (_drawing) _penRow(),
              _toolbar(),
            ],
          ),
        ),
      ),
    );
  }
}