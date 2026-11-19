import 'dart:convert';

import 'package:frontend/config.dart';
import 'package:http/http.dart' as http; 
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';



enum Who {
  blue(label: 'Joaquin', paper: Color(0xFFCDEBFF), envelope: Color(0xFF29A8F0)),
  yellow(label: 'Jenn', paper: Color(0xFFFFF1B0), envelope: Color(0xFF9BD93C));


  const Who({required this.label, required this.paper, required this.envelope});


  final String label;
  final Color paper;
  final Color envelope;


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
  });

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
    text: (j['text'] as String?) ?? '' 
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


  Future<void> send(String text) async {
    final res = await http
      .post(
        Uri.parse('${Config.apiBase}/letters'),
        headers: {..._auth, 'Content-Type': 'application.json'},
        body: jsonEncode({'text': text}),
      ).timeout(_timeout);

      if (res.statusCode != 201) {
        throw Exception('Send Failed (${res.statusCode})');
      }
  }
}

final letterRepository = LetterRepository();