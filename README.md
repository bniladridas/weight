# Weight CLI
*A digital mood ring for your text messages*

Ever wonder if that text you're about to send sounds too intense? Weight helps you check the emotional tone of your messages before hitting send.

Sometimes we write when we're stressed, angry, or overwhelmed - and it shows. This tool gives you a quick emotional temperature check.

## Install

**Option 1: Global Dart package (all platforms)**
```bash
dart pub global activate --source path .
```

**Option 2: Native binary**
```bash
# Compile
dart compile exe bin/weight_cli.dart -o weight

# macOS/Linux: Add to PATH
sudo cp weight /usr/local/bin/weight

# Windows: Copy to a folder in your PATH or add current folder to PATH
```

## Use
```bash
weight "message"    # analyze
weight --tui        # interface
weight --threshold 0.5  # set panic level
weight --help       # options
```

## Levels
- 🟢 CALM (0.0-0.2)
- 🔵 AWARE (0.3-0.4) 
- 🟡 TENSE (0.5-0.6)
- 🔴 STRESSED (0.7-0.8)
- 🚨 OVERWHELMED (0.9-1.0)
