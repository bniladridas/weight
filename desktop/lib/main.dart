import 'package:flutter/material.dart';
import 'package:weight_cli/core/weight_analyzer.dart';

void main() => runApp(WeightApp());

class WeightApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight CLI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0D1117),
        fontFamily: 'Courier',
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.green, fontFamily: 'Courier'),
        ),
      ),
      home: WeightHome(),
    );
  }
}

class WeightHome extends StatefulWidget {
  @override
  _WeightHomeState createState() => _WeightHomeState();
}

class _WeightHomeState extends State<WeightHome> {
  final _controller = TextEditingController();
  WeightResult? _result;
  final _analyzer = WeightAnalyzer(Config.load());
  List<String> _history = [];

  void _analyzeText() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _result = _analyzer.analyze(_controller.text);
      _history.insert(0, _controller.text);
      if (_history.length > 5) _history.removeLast();
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CLI-style header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ' Weight ',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '─' * 50,
              style: TextStyle(color: Colors.grey, fontFamily: 'Courier'),
            ),
            SizedBox(height: 20),

            // Input area
            Row(
              children: [
                Text(
                  '> ',
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: 'Courier',
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'Courier',
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter message...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (_) => _analyzeText(),
                  ),
                ),
              ],
            ),

            // Result display
            if (_result != null) ...[
              SizedBox(height: 10),
              Text(
                '${_result!.score.toStringAsFixed(2)} ${_result!.display}',
                style: TextStyle(
                  color: _result!.score > _analyzer.config.threshold
                      ? Colors.red
                      : Colors.green,
                  fontFamily: 'Courier',
                ),
              ),
            ],

            SizedBox(height: 30),

            // History section
            if (_history.isNotEmpty) ...[
              Text(
                'Recent:',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 10),
              ..._history.take(5).map((msg) {
                final result = _analyzer.analyze(msg);
                return Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${result.display} ${msg.length > 45 ? msg.substring(0, 45) + '...' : msg}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ],

            Spacer(),

            // Footer
            Text(
              'ESC quit • Enter analyze',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Courier',
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
