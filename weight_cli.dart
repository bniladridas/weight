#!/usr/bin/env dart

import 'dart:io';
import 'dart:math';

class WeightAnalyzer {
  static const Map<String, double> stressKeywords = {
    'urgent': 0.8,
    'critical': 0.9,
    'emergency': 1.0,
    'asap': 0.7,
    'immediately': 0.8,
    'deadline': 0.6,
    'failed': 0.7,
    'error': 0.5,
    'panic': 1.0,
    'crisis': 0.9,
    'fired': 1.0,
    'terminated': 0.9,
    'lawsuit': 0.8,
    'sue': 0.7,
    'hospital': 0.6,
    'accident': 0.7
  };

  static double calculateWeight(String text) {
    final lower = text.toLowerCase();
    double sentiment = 0.0;
    double urgency = 0.0;
    double volatility = 0.0;

    // Sentiment from keywords
    for (final entry in stressKeywords.entries) {
      if (lower.contains(entry.key)) {
        sentiment = max(sentiment, entry.value);
      }
    }

    // Urgency from caps and punctuation
    final capsRatio =
        text.replaceAll(RegExp(r'[^A-Z]'), '').length / max(text.length, 1);
    final exclamationCount = '!'.allMatches(text).length;
    urgency = min(1.0, capsRatio * 2 + exclamationCount * 0.2);

    // Volatility from punctuation density
    final punctuation = RegExp(r'[!?.,;:]').allMatches(text).length;
    volatility = min(1.0, punctuation / max(text.length / 10, 1));

    return min(1.0, sentiment * 0.5 + urgency * 0.3 + volatility * 0.2);
  }

  static String getWeightDisplay(double weight) {
    if (weight <= 0.3) return '\x1B[32m●\x1B[0m CHILL';
    if (weight <= 0.6) return '\x1B[33m●\x1B[0m NOTEWORTHY';
    if (weight <= 0.8) return '\x1B[31m●\x1B[0m HEAVY';
    return '\x1B[91m●\x1B[0m HIGH PANIC';
  }

  static void displayMessage(String message, double weight) {
    final display = getWeightDisplay(weight);
    print('Weight: ${weight.toStringAsFixed(2)} $display');

    if (weight > 0.8) {
      print(
          '\x1B[31m⚠️  High stress content detected. Press Enter to reveal...\x1B[0m');
      stdin.readLineSync();
    }

    print('Message: $message');
  }
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart weight_cli.dart "your message here"');
    print('   or: dart weight_cli.dart --interactive');
    return;
  }

  if (args[0] == '--interactive') {
    print('Weight CLI - Interactive Mode (type "exit" to quit)');
    while (true) {
      stdout.write('> ');
      final input = stdin.readLineSync();
      if (input == null || input.toLowerCase() == 'exit') break;

      final weight = WeightAnalyzer.calculateWeight(input);
      WeightAnalyzer.displayMessage(input, weight);
      print('');
    }
  } else {
    final message = args.join(' ');
    final weight = WeightAnalyzer.calculateWeight(message);
    WeightAnalyzer.displayMessage(message, weight);
  }
}
