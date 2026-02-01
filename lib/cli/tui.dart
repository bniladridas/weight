import 'dart:io';
import 'dart:math';
import '../core/weight_analyzer.dart';

class TUI {
  final WeightAnalyzer analyzer;
  final Config config;
  List<String> history = [];
  int historyIndex = 0;
  String currentInput = '';

  TUI(this.analyzer, this.config);

  void run() {
    try {
      _hideCursor();
      _clearScreen();
      _drawHeader();
      _drawInterface();

      stdin.echoMode = false;
      stdin.lineMode = false;

      stdin.listen((data) {
        final key = String.fromCharCodes(data);
        _handleInput(key);
      }, onError: (error) {
        _cleanup();
        exit(1);
      });
    } catch (e) {
      _cleanup();
      print('TUI Error: $e');
      exit(1);
    }
  }

  void _hideCursor() => stdout.write('\x1B[?25l');
  void _showCursor() => stdout.write('\x1B[?25h');
  void _clearScreen() => stdout.write('\x1B[2J\x1B[H');
  void _moveTo(int row, int col) => stdout.write('\x1B[${row};${col}H');

  void _drawHeader() {
    _moveTo(1, 1);
    stdout.write('\x1B[44m\x1B[37m Weight \x1B[0m');
    _moveTo(2, 1);
    stdout.write('─' * 20);
  }

  void _drawInterface() {
    _moveTo(4, 1);
    stdout.write('> ');
    _moveTo(5, 1);
    stdout.write('\x1B[K');
    _drawHistory();
    _drawStats();
  }

  void _drawHistory() {
    _moveTo(7, 1);

    for (int i = 0; i < 5; i++) {
      _moveTo(7 + i, 1);
      stdout.write('\x1B[K');
    }

    final recentCount = min(5, history.length);
    for (int i = 0; i < recentCount; i++) {
      final msgIndex = history.length - 1 - i;
      if (msgIndex >= 0 && msgIndex < history.length) {
        final msg = history[msgIndex];
        final result = analyzer.analyze(msg);
        _moveTo(7 + i, 1);
        stdout.write(
            '${result.display} ${msg.length > 45 ? msg.substring(0, 45) + '...' : msg}');
      }
    }
  }

  void _drawStats() {
    _moveTo(13, 1);
    if (history.isNotEmpty && history.length > 0) {
      try {
        final avgWeight = history
                .map((msg) => analyzer.calculateWeight(msg))
                .reduce((a, b) => a + b) /
            history.length;
        final avgResult = WeightResult(avgWeight, '', '', '');
        final tempAnalyzer = WeightAnalyzer(config);
        final displayResult = tempAnalyzer.analyze('dummy');
        stdout.write('${displayResult.display}');
      } catch (e) {
        stdout.write('● CALM');
      }
    }
    _moveTo(15, 1);
    stdout.write('\x1B[90mESC quit\x1B[0m');
  }

  void _handleInput(String key) {
    final codes = key.codeUnits;

    if (codes.length == 3 && codes[0] == 27 && codes[1] == 91) {
      switch (codes[2]) {
        case 65:
          _navigateHistory(-1);
          break;
        case 66:
          _navigateHistory(1);
          break;
      }
      return;
    }

    switch (codes[0]) {
      case 27:
        _cleanup();
        exit(0);
      case 10:
      case 13:
        _processMessage();
        break;
      case 127:
      case 8:
        if (currentInput.isNotEmpty) {
          currentInput = currentInput.substring(0, currentInput.length - 1);
          _updateInputLine();
          _moveTo(4, 3 + currentInput.length);
        }
        break;
      case 3:
        _cleanup();
        exit(0);
      default:
        if (codes[0] >= 32 && codes[0] <= 126) {
          currentInput += key;
          _updateInputLine();
          _moveTo(4, 3 + currentInput.length);
        }
    }
  }

  void _updateInputLine() {
    _moveTo(4, 3);
    stdout.write('\x1B[K');
    stdout.write(currentInput);
  }

  void _processMessage() {
    if (currentInput.trim().isEmpty) return;

    final result = analyzer.analyze(currentInput);
    history.add(currentInput);

    _moveTo(5, 1);
    stdout.write('\x1B[K');

    if (result.score > config.threshold) {
      stdout.write(
          '\x1B[31m⚠️  ${result.score.toStringAsFixed(2)} ${result.display}\x1B[0m');
    } else {
      stdout.write('${result.score.toStringAsFixed(2)} ${result.display}');
    }

    currentInput = '';
    historyIndex = history.length;

    _updateInputLine();
    _drawHistory();
    _drawStats();

    _moveTo(4, 3 + currentInput.length);
  }

  void _navigateHistory(int direction) {
    if (history.isEmpty) return;

    final newIndex = historyIndex + direction;
    historyIndex = newIndex.clamp(0, history.length);

    if (historyIndex < history.length) {
      currentInput = history[historyIndex];
    } else {
      currentInput = '';
    }

    _updateInputLine();
    _moveTo(4, 3 + currentInput.length);
  }

  void _cleanup() {
    _showCursor();
    stdin.echoMode = true;
    stdin.lineMode = true;
    _clearScreen();
  }
}

void displayMessage(String message, WeightResult result, Config config,
    {bool showWeight = true}) {
  if (showWeight) {
    print('Weight: ${result.score.toStringAsFixed(2)} ${result.display}');
  }

  if (result.score > config.threshold) {
    print(
        '\x1B[31m⚠️  Mental overload detected. Press Enter to reveal...\x1B[0m');
    stdin.readLineSync();
  }

  print('Message: $message');
}
