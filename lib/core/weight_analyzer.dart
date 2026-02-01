import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';

class WeightResult {
  final double score;
  final String level;
  final String emoji;
  final String display;

  WeightResult(this.score, this.level, this.emoji, this.display);
}

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

  WeightResult analyze(String text) {
    final weight = calculateWeight(text);
    final level = _getLevel(weight);
    final emoji = _getEmoji(weight);
    final display = _getDisplay(weight);

    return WeightResult(weight, level, emoji, display);
  }

  double calculateWeight(String text) {
    if (text.trim().isEmpty) return 0.0;

    final sentiment = _calculateSentiment(text);
    final urgency = _calculateUrgency(text);
    final volatility = _calculateVolatility(text);
    final length = _calculateLength(text);

    final weight =
        sentiment * 0.5 + urgency * 0.25 + volatility * 0.15 + length * 0.1;
    return weight.clamp(0.0, 1.0);
  }

  String _getLevel(double weight) {
    if (weight <= 0.2) return 'CALM';
    if (weight <= 0.4) return 'AWARE';
    if (weight <= 0.6) return 'TENSE';
    if (weight <= 0.8) return 'STRESSED';
    return 'OVERWHELMED';
  }

  String _getEmoji(double weight) {
    if (weight <= 0.2) return '🟢';
    if (weight <= 0.4) return '🔵';
    if (weight <= 0.6) return '🟡';
    if (weight <= 0.8) return '🔴';
    return '🚨';
  }

  String _getDisplay(double weight) {
    if (weight <= 0.2) return '\x1B[32m●\x1B[0m CALM';
    if (weight <= 0.4) return '\x1B[36m●\x1B[0m AWARE';
    if (weight <= 0.6) return '\x1B[33m●\x1B[0m TENSE';
    if (weight <= 0.8) return '\x1B[31m●\x1B[0m STRESSED';
    return '\x1B[91m●\x1B[0m OVERWHELMED';
  }

  double _calculateSentiment(String text) {
    final lower = text.toLowerCase();
    double maxWeight = 0.0;

    for (final entry in config.keywords.entries) {
      if (lower.contains(entry.key)) {
        maxWeight = maxWeight > entry.value ? maxWeight : entry.value;
      }
    }

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

    final capsCount = text.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalLetters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (totalLetters > 0) {
      final capsRatio = capsCount / totalLetters;
      urgency += capsRatio * 0.6;
    }

    final exclamations = '!'.allMatches(text).length;
    final questions = '?'.allMatches(text).length;
    urgency += (exclamations * 0.2) + (questions * 0.1);

    if (text.toLowerCase().contains('now')) urgency += 0.3;
    if (text.toLowerCase().contains('today')) urgency += 0.2;
    if (text.toLowerCase().contains('asap')) urgency += 0.4;

    return urgency.clamp(0.0, 1.0);
  }

  double _calculateVolatility(String text) {
    final punctuation = RegExp(r'[!?.,;:()-]').allMatches(text).length;
    final words = text.split(RegExp(r'\s+')).length;

    if (words == 0) return 0.0;

    final density = punctuation / words;
    return (density * 0.5).clamp(0.0, 1.0);
  }

  double _calculateLength(String text) {
    final words = text.split(RegExp(r'\s+')).length;

    if (words <= 3) return 0.0;
    if (words <= 8) return 0.1;
    if (words <= 15) return 0.2;
    if (words <= 25) return 0.3;
    return 0.4;
  }
}
