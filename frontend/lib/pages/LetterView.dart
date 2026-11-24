import 'package:frontend/Widget/LetterPaper.dart';
import 'package:frontend/data/letter_repository.dart';
import 'package:material_ui/material_ui.dart';

class LetterView extends StatefulWidget {
  const LetterView({super.key, required this.letterId});

  final String letterId;

  @override
  State<LetterView> createState() => _LetterView();
}

class _LetterView extends State<LetterView> {
  late final Future<Letter> _future = letterRepository.get(widget.letterId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/temp_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<Letter>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              debugPrint('Letter open error: ${snap.error}');
              return const Center(child: Text('Could not open this letter'));
            }

            final letter = snap.data!;
            final date = MaterialLocalizations.of(context)
                .formatMediumDate(letter.sentAt.toLocal());

            return Column(
              children: [
                Text(
                  'From ${letter.from.label} - $date',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LetterPaper(
                    paperColor: letter.from.paper,
                    text: letter.text,
                    items: letter.items,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}