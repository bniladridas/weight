#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:weight_cli/core/weight_analyzer.dart';
import 'package:weight_cli/cli/tui.dart';

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

      final result = analyzer.analyze(input);
      displayMessage(input, result, config, showWeight: !quiet);
      print('');
    }
  } else if (results.rest.isNotEmpty) {
    final message = results.rest.join(' ');
    final result = analyzer.analyze(message);
    displayMessage(message, result, config, showWeight: !quiet);
  } else {
    print('Usage: weight "your message" or weight --help');
  }
}
