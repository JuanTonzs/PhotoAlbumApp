import 'dart:convert';

import 'package:frontend/config.dart';
import 'package:http/http.dart' as http; 
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/data/letter_items.dart';



enum Who {
  blue(
    label: 'Joaquin', 
    paper: Color(0xFFCDEBFF), 
    envelope: Color(0xFF29A8F0),
    envelopeAsset: 'assets/images/envelopes/blue_envelope.gif'
  ),
  
  yellow(
    label: 'Jenn', 
    paper: Color(0xFFFFF1B0), 
    envelope: Color(0xFF9BD93C),
    envelopeAsset: 'assets/images/envelopes/green_envelope.gif'
  );


  const Who({required this.label, required this.paper, required this.envelope, required this.envelopeAsset});


  final String label;
  final Color paper;
  final Color envelope;
  final String envelopeAsset;
  


  Who get other => this == Who.blue ? Who.yellow : Who.blue;

  static Who parse(String s) => s == 'yellow' ? Who.yellow : Who.blue;
}

// Whos using which phone 
class Session {
  static Who? me;

  static Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString('me');
    me = saved == null ? null : Who.parse(saved);
  }


  static Future<void> setMe(Who who) async {
    me = who;
    await (await SharedPreferences.getInstance()).setString('me', who.name);
  }

  static String get token =>
    me == Who.yellow ? Config.tokenYellow : Config.tokenBlue;
}


class Letter {
  const Letter({
    required this.id,
    required this.from,
    required this.to,
    required this.sentAt,
    required this.readAt,
    required this.preview,
    this.text = '',
    this.items = const [],
  });

  final List<LetterItem> items;
  final String id;
  final Who from;
  final Who to;
  final DateTime sentAt;
  final DateTime? readAt;
  final String preview;
  final String text;

  factory Letter.fromJson(Map<String, dynamic> j) => Letter(
    id: j['id'] as String,
    from: Who.parse(j['to'] as String),
    to: Who.parse(j['to'] as String),
    sentAt: DateTime.parse(j['sentAt'] as String),
    readAt: j['readAt'] == null ? null : DateTime.parse(j['readAt'] as String),
    preview: (j['preview'] as String?) ?? '',
    text: (j['text'] as String?) ?? '' ,
    items: [
      for (final i in (j['items'] as List? ?? const[]))
        LetterItem.fromJson(i as Map<String, dynamic>),
    ]
  );

}


class LetterRepository {
  static const _timeout = Duration(seconds: 30);

  Map<String, String> get _auth => {'Authorization': 'Bearer ${Session.token}'};
  dynamic _decode(http.Response res) => jsonDecode(utf8.decode(res.bodyBytes));

  Future<List<Letter>> list() async {
    final res = await http
      .get(Uri.parse('${Config.apiBase}/letters'), headers: _auth)
      .timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Could not load letters (${res.statusCode})');
    }

    return (_decode(res) as List)
      .map((j) => Letter.fromJson(j as Map<String, dynamic>))
      .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }


  Future<Letter> get(String id) async {
    final res = await http
      .get(Uri.parse('${Config.apiBase}/letters/$id'), headers: _auth)
      .timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Could not open letter (${res.statusCode})');
    }

    return Letter.fromJson(_decode(res) as Map<String, dynamic>);
  }


  Future<void> send(String text, List<LetterItem> items) async {
    final res = await http
      .post(
        Uri.parse('${Config.apiBase}/letters'),
        headers: {..._auth, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'items': [for (final i in items) i.toJson()],
        }),
      ).timeout(_timeout);

      if (res.statusCode != 201) {
        throw Exception('Send Failed (${res.statusCode}) || ${res.body}');
      }
  }
}

final letterRepository = LetterRepository();