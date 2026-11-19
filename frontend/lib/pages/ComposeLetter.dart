import 'package:frontend/data/letter_repository.dart';
import 'package:material_ui/material_ui.dart';

class ComposeLetter extends StatefulWidget {
  const ComposeLetter({super.key, required this.from});

  final Who from;

  @override
  State<ComposeLetter> createState() => _ComposeLetter();
}

class _ComposeLetter extends State<ComposeLetter> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Write something first!'),),
      );

      return;
    }

    setState(() {
      _sending = true;
    });


    try {
      await letterRepository.send(text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Send error: $e');
      if (!mounted) return;
      
      setState(() {
        _sending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send. Check your connection.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final to = widget.from.other;


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),

        title: Text('To ${to.label}'),
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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/images/temp_background.jpg'),
            fit: BoxFit.cover
          ),
        ),

        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.from.paper,
            border: Border.all(color: Colors.black26),
            boxShadow: [
              BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(3, 3))
            ],
          ),

          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            maxLength: 4000,
            textAlignVertical: TextAlignVertical.top,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: Colors.black87,
            style: TextStyle(color: Colors.black87, fontSize: 24, height: 1.4),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Dear ${to.label}',
              hintStyle: TextStyle(color: Colors.black38),
            ),
          ),
        ),
      ),
    );
  }
}