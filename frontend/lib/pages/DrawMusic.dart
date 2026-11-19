import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:material_ui/material_ui.dart';


const _beats = 8;
const _stepsPerBeat = 4;
const _steps = _beats * _stepsPerBeat;
const _bpm = 100;
const _scale = [0, 2, 4, 7, 9]; // Pentatonic
const _rootMidi = 48; //C3
const _octaves = 3;
const _overlapSteps = 0.5;

const _colours = [
  Color(0xFFFF8FB1),
    Color(0xFF7FE7FF),
    Color(0xFFFFE27A),
    Color(0xFF9CFFB0),
];

const _instruments = [0, 11, 73, 24];

class _Stroke {
  _Stroke(this.colorIndex);

  final int colorIndex;
  final List<Offset> points = [];
}

class DrawMusic extends StatefulWidget{
  const DrawMusic({super.key});

  @override
  State<StatefulWidget> createState() => _DrawMusic();
}


class _DrawMusic extends State<DrawMusic> with SingleTickerProviderStateMixin {
  final _midi = MidiPro();
  int? _sfId;
  String? _error;


  final List<_Stroke> _strokes = [];
  int _color = 0;
  Size _canvas = Size.zero;

  List<Set<(int, int)>> _plan = List.generate(_steps, (_) => <(int, int)>{});

  late final Ticker _ticker = createTicker(_onTick);
  final _playhead = ValueNotifier<double>(0);
  bool _playing = false;
  int _lastStep = -1;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _playhead.dispose();
    if(_midi.isInitialized) _midi.dispose();
    super.dispose();
  }

 Future<void> _setup() async {
  try {
    if (!_midi.isInitialized) await _midi.init(bufferSize: 256);

    final id = await _midi.loadSoundfontAsset(
      assetPath: 'assets/SoundFonts/FluidR3.sf2',
      bank: 0,
      program: 0,
    );

    for (var c = 0; c < _instruments.length; c++) {
      await _midi.selectInstrument(
        sfId: id,
        channel: c,
        bank: 0,
        program: _instruments[c],
      );
    }

    await _midi.setReverb(enabled: true, roomSize: 0.6, level: 0.9);

    if (!mounted) return;
    setState(() => _sfId = id);
  } catch (e) {
    debugPrint('Audio Setup Error  $e');
    if (!mounted) return;
    setState(() => _error = 'Could not start the sound engine');
  }
}


  int _noteForY(double y) {
    final count = _scale.length * _octaves;
    final i = ((1 - y / _canvas.height) * count).floor().clamp(0 , count - 1).toInt();
    return _rootMidi + (i ~/ _scale.length) * 12 + _scale[i % _scale.length];
  }

  int _stepForX(double x) => (x / _canvas.width * _steps).floor().clamp(0, _steps - 1).toInt();

  void _addToPlan(int colourIndex, Offset p) {
    _plan[_stepForX(p.dx)].add((colourIndex, _noteForY(p.dy)));
  }

  void _rebuildPlan() {
    _plan = List.generate(_steps, (_) => <(int, int)>{});

    for (final s in _strokes) {
      for (final p in s.points) {
        _addToPlan(s.colorIndex, p);
      }
    }
  }


int _gen = 0; // bumped on stop so stale release timers do nothing

void _playNote(int channel, int key, {required int velocity, required int ms}) {
  final id = _sfId;
  if (id == null) return;

  final gen = _gen;
  _midi.playNote(sfId: id, channel: channel, key: key, velocity: velocity);

  Future.delayed(Duration(milliseconds: ms), () {
    if (mounted && _midi.isInitialized && gen == _gen) {
      _midi.stopNote(sfId: id, channel: channel, key: key);
    }
  });
}

void _playStep(int step) {
  final stepMs = 60000 / _bpm / _stepsPerBeat;

  for (final n in _plan[step]) {
    if (step > 0 && _plan[step - 1].contains(n)) continue;

    var len = 1;
    while (step + len < _steps && _plan[step + len].contains(n)) {
      len++;
    }

    final endsLoop = step + len >= _steps;
    final ms = endsLoop
        ? (len * stepMs - 20).round()
        : (len * stepMs + stepMs * _overlapSteps).round();

    _playNote(n.$1, n.$2, velocity: 90, ms: ms);
  }
}


  void _onTick(Duration elapsed) {
    final loopMs = _beats * 60000 / _bpm;
    final fraction = (elapsed.inMilliseconds % loopMs) / loopMs;
    _playhead.value = fraction;

    final step = (fraction * _steps).floor();
    if (step != _lastStep) {
      _lastStep = step;
      _playStep(step);
    }
  }


  void _togglePlay() {
    if (_playing) {
      _ticker.stop();
      _midi.panic();
      _playhead.value = 0;
    } else {
      _lastStep = -1;
      _ticker.start();
    }

    setState(() => _playing = !_playing);
  }


  void _onDown(Offset p) {
    final stroke = _Stroke(_color)..points.add(p);
    setState(() => _strokes.add(stroke));
    _addToPlan(_color, p);
    _playNote(_color, _noteForY(p.dy), velocity: 100, ms: 300);
  }

  void _onMove(Offset p) {
    if (_strokes.isEmpty) return;
    final stroke = _strokes.last;
    setState(() => stroke.points.add(p));
    _addToPlan(stroke.colorIndex, p);
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    _rebuildPlan();
  }

  void _clear() {
    setState(() => _strokes.clear());
    _rebuildPlan();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),

      body: _error != null
      ? Center(child: Text(_error!))
      : Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white, width: 2),
              ),

              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, box) {
                    _canvas = box.biggest;
                    return Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => _onDown(e.localPosition),
                      onPointerMove: (e) => _onMove(e.localPosition),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _CanvasPainter(_strokes, _playhead),
                      ),
                    );
                  }
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                for (var i = 0; i < _colours.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _colours[i],
                        border: Border.all(
                          color: _color == i
                            ? Colors.white
                            : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),

                  Spacer(),

                  IconButton(
                    tooltip: 'Undo',
                    onPressed: _undo, 
                    icon: Icon(Icons.undo),
                  ),
                  

                  IconButton(
                    tooltip: 'Clear',
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline),
                  ),
                  
                  SizedBox(width: 8,),

                  ElevatedButton(
                    onPressed: _togglePlay, 
                    child: Icon(_playing ? Icons.stop : Icons.play_arrow),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}





class _CanvasPainter extends CustomPainter {
  _CanvasPainter(this.strokes, this.playhead) : super(repaint: playhead);

  final List<_Stroke> strokes;
  final ValueNotifier<double> playhead;


  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;

    for (var i = 0; i < _beats; i++) {
      final x = size.width / _beats * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }


    for (final s in strokes) {
      final paint = Paint()
      ..color = _colours[s.colorIndex]
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, 5, paint..style = PaintingStyle.fill);
      } else {
        final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
        for (final p in s.points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }

        canvas.drawPath(path, paint);
      }
    }

    final x = playhead.value * size.width;
    canvas.drawLine(
      Offset(x, 0), 
      Offset(x, size.height), 
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}