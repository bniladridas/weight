#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

class Config {
  Map<String, double> keywords;
  Map<String, double> weights;
  double threshold;

  Config({
    required this.keywords,
    required this.weights,
    required this.threshold,
  });

  static Config load() {
    final configPath = '${Platform.environment['HOME']}/.weight_cli.yaml';
    final file = File(configPath);

    if (!file.existsSync()) {
      final defaultConfig = Config.defaultConfig();
      defaultConfig.save();
      return defaultConfig;
    }

    final yaml = loadYaml(file.readAsStringSync());
    return Config(
      keywords: Map<String, double>.from(yaml['keywords'] ?? {}),
      weights: Map<String, double>.from(yaml['weights'] ?? {}),
      threshold: yaml['threshold']?.toDouble() ?? 0.8,
    );
  }

  static Config defaultConfig() {
    return Config(
      keywords: {
        'urgent': 0.7,
        'critical': 0.9,
        'emergency': 1.0,
        'asap': 0.6,
        'immediately': 0.7,
        'deadline': 0.5,
        'failed': 0.8,
        'error': 0.4,
        'panic': 1.0,
        'crisis': 0.9,
        'fired': 1.0,
        'terminated': 0.9,
        'worried': 0.4,
        'anxious': 0.5,
        'stressed': 0.6,
        'overwhelmed': 0.8,
        'breaking': 0.7,
        'disaster': 0.8,
        'trouble': 0.5,
        'problem': 0.3,
        'help': 0.3,
        'issue': 0.4,
        'concern': 0.4,
        'warning': 0.6,
        'alert': 0.5,
        'attention': 0.4,
        'serious': 0.5,
        'important': 0.3,
        'rush': 0.6,
        'hurry': 0.5,
        'quick': 0.4,
        'fast': 0.3,
      },
      weights: {
        'sentiment': 0.4,
        'urgency': 0.3,
        'volatility': 0.2,
        'complexity': 0.1
      },
      threshold: 0.7,
    );
  }

  void save() {
    final configPath = '${Platform.environment['HOME']}/.weight_cli.yaml';
    final yaml = {
      'keywords': keywords,
      'weights': weights,
      'threshold': threshold,
    };
    File(configPath).writeAsStringSync(jsonEncode(yaml));
  }
}

class WeightAnalyzer {
  final Config config;

  WeightAnalyzer(this.config);

  double calculateWeight(String text) {
    if (text.trim().isEmpty) return 0.0;

    final sentiment = _calculateSentiment(text);
    final urgency = _calculateUrgency(text);
    final volatility = _calculateVolatility(text);
    final length = _calculateLength(text);

    // Balanced weighted calculation
    final weight =
        sentiment * 0.5 + urgency * 0.25 + volatility * 0.15 + length * 0.1;

    return weight.clamp(0.0, 1.0);
  }

  double _calculateSentiment(String text) {
    final lower = text.toLowerCase();
    double maxWeight = 0.0;

    // Check for stress keywords
    for (final entry in config.keywords.entries) {
      if (lower.contains(entry.key)) {
        maxWeight = maxWeight > entry.value ? maxWeight : entry.value;
      }
    }

    // Base sentiment from text tone
    if (lower.contains('please') || lower.contains('thank'))
      maxWeight = maxWeight > 0.1 ? maxWeight : 0.1;
    if (lower.contains('help') || lower.contains('need'))
      maxWeight = maxWeight > 0.3 ? maxWeight : 0.3;
    if (lower.contains('can you') || lower.contains('could you'))
      maxWeight = maxWeight > 0.2 ? maxWeight : 0.2;

    return maxWeight;
  }

  double _calculateUrgency(String text) {
    double urgency = 0.0;

    // Caps analysis
    final capsCount = text.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalLetters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (totalLetters > 0) {
      final capsRatio = capsCount / totalLetters;
      urgency += capsRatio * 0.6;
    }

    // Punctuation urgency
    final exclamations = '!'.allMatches(text).length;
    final questions = '?'.allMatches(text).length;
    urgency += (exclamations * 0.2) + (questions * 0.1);

    // Time-sensitive words
    if (text.toLowerCase().contains('now')) urgency += 0.3;
    if (text.toLowerCase().contains('today')) urgency += 0.2;
    if (text.toLowerCase().contains('asap')) urgency += 0.4;

    return urgency.clamp(0.0, 1.0);
  }

  double _calculateVolatility(String text) {
    // Punctuation density
    final punctuation = RegExp(r'[!?.,;:()-]').allMatches(text).length;
    final words = text.split(RegExp(r'\s+')).length;

    if (words == 0) return 0.0;

    final density = punctuation / words;
    return (density * 0.5).clamp(0.0, 1.0);
  }

  double _calculateLength(String text) {
    // Longer messages tend to be more complex/stressful
    final words = text.split(RegExp(r'\s+')).length;

    if (words <= 3) return 0.0; // Very short = calm
    if (words <= 8) return 0.1; // Short = slight awareness
    if (words <= 15) return 0.2; // Medium = aware
    if (words <= 25) return 0.3; // Long = tense
    return 0.4; // Very long = stressed
  }

  String getWeightDisplay(double weight) {
    if (weight <= 0.2) return '\x1B[32m●\x1B[0m CALM';
    if (weight <= 0.4) return '\x1B[36m●\x1B[0m AWARE';
    if (weight <= 0.6) return '\x1B[33m●\x1B[0m TENSE';
    if (weight <= 0.8) return '\x1B[31m●\x1B[0m STRESSED';
    return '\x1B[91m●\x1B[0m OVERWHELMED';
  }

  void displayMessage(String message, double weight, {bool showWeight = true}) {
    if (showWeight) {
      final display = getWeightDisplay(weight);
      print('Weight: ${weight.toStringAsFixed(2)} $display');
    }

    if (weight > config.threshold) {
      print(
          '\x1B[31m⚠️  Mental overload detected. Press Enter to reveal...\x1B[0m');
      stdin.readLineSync();
    }

    print('Message: $message');
  }
}

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
    stdout.write('\x1B[K'); // Clear result line
    _drawHistory();
    _drawStats();
  }

  void _drawHelp() {
    _moveTo(20, 1);
    stdout.write(
        '\x1B[90mType your message and press Enter to analyze your mental state\x1B[0m');
  }

  void _drawHistory() {
    _moveTo(7, 1);

    // Clear previous history lines
    for (int i = 0; i < 5; i++) {
      _moveTo(7 + i, 1);
      stdout.write('\x1B[K');
    }

    // Safely handle large history arrays
    final recentCount = min(5, history.length);
    for (int i = 0; i < recentCount; i++) {
      final msgIndex = history.length - 1 - i;
      if (msgIndex >= 0 && msgIndex < history.length) {
        final msg = history[msgIndex];
        final weight = analyzer.calculateWeight(msg);
        final display = analyzer.getWeightDisplay(weight);
        _moveTo(7 + i, 1);
        stdout.write(
            '$display ${msg.length > 45 ? msg.substring(0, 45) + '...' : msg}');
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
        stdout.write('${analyzer.getWeightDisplay(avgWeight)}');
      } catch (e) {
        stdout.write('● CALM'); // Fallback if calculation fails
      }
    }
    _moveTo(15, 1);
    stdout.write('\x1B[90mESC quit\x1B[0m');
  }

  void _handleInput(String key) {
    final codes = key.codeUnits;

    // Handle ESC sequences (arrow keys)
    if (codes.length == 3 && codes[0] == 27 && codes[1] == 91) {
      switch (codes[2]) {
        case 65: // Up arrow
          _navigateHistory(-1);
          break;
        case 66: // Down arrow
          _navigateHistory(1);
          break;
      }
      return;
    }

    // Handle single key presses
    switch (codes[0]) {
      case 27: // ESC (single)
        _cleanup();
        exit(0);
      case 10: // Enter (LF)
      case 13: // Enter (CR)
        _processMessage();
        break;
      case 127: // Backspace
      case 8: // Backspace (alternative)
        if (currentInput.isNotEmpty) {
          currentInput = currentInput.substring(0, currentInput.length - 1);
          _updateInputLine();
          // Move cursor to end of remaining input
          _moveTo(4, 3 + currentInput.length);
        }
        break;
      case 3: // Ctrl+C
        _cleanup();
        exit(0);
      default:
        // Printable characters
        if (codes[0] >= 32 && codes[0] <= 126) {
          currentInput += key;
          _updateInputLine();
          // Move cursor to end of input
          _moveTo(4, 3 + currentInput.length);
        }
    }
  }

  void _updateInputLine() {
    _moveTo(4, 3);
    stdout.write('\x1B[K'); // Clear from cursor to end of line
    stdout.write(currentInput);
  }

  void _processMessage() {
    if (currentInput.trim().isEmpty) return;

    final weight = analyzer.calculateWeight(currentInput);
    history.add(currentInput);

    // Show result on line 5
    _moveTo(5, 1);
    stdout.write('\x1B[K'); // Clear line

    if (weight > config.threshold) {
      stdout.write(
          '\x1B[31m⚠️  ${weight.toStringAsFixed(2)} ${analyzer.getWeightDisplay(weight)}\x1B[0m');
    } else {
      stdout.write(
          '${weight.toStringAsFixed(2)} ${analyzer.getWeightDisplay(weight)}');
    }

    // Clear input and reset
    currentInput = '';
    historyIndex = history.length;

    // Update display
    _updateInputLine();
    _drawHistory();
    _drawStats();

    // Move cursor back to input line
    _moveTo(4, 3 + currentInput.length);
  }

  void _navigateHistory(int direction) {
    if (history.isEmpty) return;

    // Clamp to valid range to prevent crashes
    final newIndex = historyIndex + direction;
    historyIndex = newIndex.clamp(0, history.length);

    if (historyIndex < history.length) {
      currentInput = history[historyIndex];
    } else {
      currentInput = '';
    }

    _updateInputLine();
    // Move cursor to end of input
    _moveTo(4, 3 + currentInput.length);
  }

  void _cleanup() {
    _showCursor();
    stdin.echoMode = true;
    stdin.lineMode = true;
    _clearScreen();
  }
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show help')
    ..addFlag('interactive', abbr: 'i', help: 'Interactive mode')
    ..addFlag('tui', help: 'Terminal User Interface mode')
    ..addFlag('config', abbr: 'c', help: 'Show config file location')
    ..addFlag('quiet', abbr: 'q', help: 'Hide weight display')
    ..addOption('threshold', abbr: 't', help: 'Set panic threshold (0.0-1.0)');

  final results = parser.parse(args);

  if (results['help']) {
    print('Weight CLI - Measure emotional weight of text');
    print('Usage: weight [options] "message"');
    print(parser.usage);
    return;
  }

  final config = Config.load();

  if (results['config']) {
    print('Config: ${Platform.environment['HOME']}/.weight_cli.yaml');
    return;
  }

  if (results['threshold'] != null) {
    config.threshold = double.parse(results['threshold']);
    config.save();
    print('Threshold updated to ${config.threshold}');
    return;
  }

  final analyzer = WeightAnalyzer(config);
  final quiet = results['quiet'];

  if (results['tui']) {
    final tui = TUI(analyzer, config);
    tui.run();
    return;
  }

  if (results['interactive']) {
    print('Weight CLI v1.0.0 - Interactive Mode (type "exit" to quit)');
    while (true) {
      stdout.write('> ');
      final input = stdin.readLineSync();
      if (input == null || input.toLowerCase() == 'exit') break;

      final weight = analyzer.calculateWeight(input);
      analyzer.displayMessage(input, weight, showWeight: !quiet);
      print('');
    }
  } else if (results.rest.isNotEmpty) {
    final message = results.rest.join(' ');
    final weight = analyzer.calculateWeight(message);
    analyzer.displayMessage(message, weight, showWeight: !quiet);
  } else {
    print('Usage: weight "your message" or weight --help');
  }
}
