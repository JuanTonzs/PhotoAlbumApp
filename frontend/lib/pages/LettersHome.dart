import 'package:frontend/data/letter_repository.dart';
import 'package:frontend/pages/ComposeLetter.dart';
import 'package:frontend/pages/LetterView.dart';
import 'package:material_ui/material_ui.dart';


class LettersHome extends StatefulWidget {
  const LettersHome({super.key});

  @override
  State<LettersHome> createState() => _LettersHome();
}


class _LettersHome extends State<LettersHome> {
  bool _loaded = false;
  Future<List<Letter>>? _future;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Session.load();
    if(!mounted) return;
    setState(() {
      _loaded = true;
      if (Session.me != null) _future = letterRepository.list();
    });
  }


  void _reload() {
    setState(() {
      _future = letterRepository.list();
    });
  }

  Future<void> _choose(Who who) async {
    await Session.setMe(who);
    if (!mounted) return;
    _reload();
  }


  Future<void> _open(Letter letter) async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => LetterView(letterId: letter.id)),
    );

    if (mounted) _reload();
  }

  Future<void> _compose() async {
    final sent = await Navigator.push<bool>(
      context, 
      MaterialPageRoute(builder: (_) => ComposeLetter(from: Session.me!)),
    );

    if (sent == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final me = Session.me;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),

        // REPLACE THE TOP WITH THIS WHEN ASSETS ARE READY
        // leading: Opacity(
        //   opacity: unread ? 1.0 : 0.6,
        //   child: Image.asset(
        //     letter.from.envelopeAsset,
        //     width: 64,
        //     fit: BoxFit.contain,
        //   ),
        // ),

        title: Text(me == null ? 'Letters' : 'Letters: ${me.label}'),
        actions: [
          if(me != null)
            IconButton(
              tooltip: 'Switch to ${me.other.label}',
              onPressed: () => _choose(me.other), 
              icon: const Icon(Icons.swap_horiz),
            ),
        ],
      ),



      body: !_loaded 
        ? Center(child: CircularProgressIndicator())
        : me == null 
          ? _picker()
          : _list(me),
      floatingActionButton: me == null
        ? null
        : FloatingActionButton(
          onPressed: _compose,
          child: Icon(Icons.edit),
        ),
    );
  }

  Widget _picker() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Who are you?', style: TextStyle(fontSize: 28),),
          const SizedBox(height: 24,),
          for (final who in Who.values) ...[
            ElevatedButton(
              onPressed: () => _choose(who),
              style: ElevatedButton.styleFrom(
                side: BorderSide(color: who.envelope, width: 3),
              ),
              child: Text("I'm ${who.label}"),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }


  Widget _list(Who me) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        try {
          await _future;
        } catch (_) {}
      }, 
      child: FutureBuilder<List<Letter>>(
        future: _future, 
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(),);
          }
          if (snap.hasError) {
            debugPrint('Letters load error: ${snap.error}');
            return ListView(
              children: [
                SizedBox(height: 200,),
                Center(child: Text('Could not load letters')),
              ],);
          }

          final letters = snap.data!;
          if (letters.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: 200,),
                Center(child: Text('No letters yet. Tap the pen to write one :)'),)
              ],
            );
          }

          return ListView.builder(
              padding: EdgeInsets.only(top: 8, bottom: 88),
              itemCount: letters.length,
              itemBuilder: (_, i) => _LetterTile(
                letter: letters[i],
                me: me,
                onTap: () => _open(letters[i])
              )
            );

          
        }
      )
    );
  }

}


class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.letter, required this.me, required this.onTap});

  final Letter letter;
  final Who me;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    final incoming = letter.to == me;
    final unread = incoming && letter.readAt == null;
    final date = MaterialLocalizations.of(context).formatMediumDate(letter.sentAt.toLocal());

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: letter.from.envelope, width: 2),
        ),

        child: ListTile(
          onTap: onTap,
          leading: Icon(
            unread ? Icons.mail : Icons.drafts,
            color: letter.from.envelope,
            size: 32,
          ),

          title: Text(incoming ? 'From ${letter.from.label}' : 'To ${letter.to.label}'),
          subtitle: Text(letter.preview, maxLines: 1, overflow: TextOverflow.ellipsis,),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(date, style: TextStyle(fontSize: 12),),
              if (unread)
                Text('NEW', style: TextStyle(fontSize: 12, color: letter.from.envelope),)
            ],
          ),
        ),
      ),
    );
  }
}