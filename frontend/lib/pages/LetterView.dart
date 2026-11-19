import 'package:frontend/data/letter_repository.dart';
import 'package:material_ui/material_ui.dart';

class LetterView extends StatefulWidget {
    const LetterView({super.key, required this.letterId});

    final String letterId;

    @override
    State<LetterView> createState() => _LetterView();
}


class _LetterView extends State<LetterView> {
    late final Future<Letter> _future = letterRepository.get

    @override
    Widget build(BuildContext contex) {
        return Scaffold(
            appBar: AppBar(
                leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                ),
            ),

            body: Container(
                 padding: EdgeInsets.all(16),
                 decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/temp_background.jpg'),
                         fit: BoxFit.cover,
                    ),
                 ),

                 child: FutureBuilder<Letter> (
                    future: _future,
                    builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                            return Center(child: CircularProgressIndicator(),);
                        }

                        if (snap.hasError) {
                            debugPrint('Letter open error: ${snap.error}');
                            return const Center(child: Text('Could not open this letter'));
                        }

                        final letter = snap.data!;
                        final date = MaterialLocalizations.of(context)
                                .formatMediumDate(letter.sentAt.toLocal());


                        return Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: letter.from.paper,
                                border: Border.all(color: Colors.black26),
                                boxShadow: const [
                                    BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(3, 3))
                                ],
                            ),

                            child: SingleChildScrollView(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            'From ${letter.from.label}',
                                            style: TextStyle(fontSize: 18, color: Colors.black54),
                                        ),
                                        Text(
                                            date,
                                            style: TextStyle(fontSize: 18, color: Colors.black54),
                                        ),
                                        Divider(color: Colors.black26, height: 32,),
                                        Text(
                                            letter.text,
                                            style: TextStyle(color: Colors.black87, fontSize: 24, height: 1.4),
                                        )
                                    ],
                                ),
                            ),
                        );
                    },
                 )
            ),

           
        );
    }
}