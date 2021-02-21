import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(HumanLifeApp());
}

class HumanLifeApp extends StatelessWidget {
  final settings = HumanLifeSettings();

  static const appName = 'Human Life Counter';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        primaryColor: Color(0xFF38618C),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Color(0xFFC0FF99),
        ),
      ),
      home: HumanLifePage(settings: settings),
    );
  }
}

class HumanLifePage extends StatelessWidget {
  final HumanLifeSettings settings;

  const HumanLifePage({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(HumanLifeApp.appName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 17, child: HumanLifeVisualization(settings)),
          // Make sure there's enough space at the bottom that the bottom sheet
          // can cover.
          Expanded(flex: 3, child: SizedBox()),
        ],
      ),
      bottomSheet: CustomizationDrawer(settings),
    );
  }
}

class HumanLifeVisualization extends StatelessWidget {
  final HumanLifeSettings settings;

  const HumanLifeVisualization(this.settings);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, child) {
          return RepaintBoundary(
            child: CustomPaint(
              painter: HumanLifePainter(
                  settings.currentAge, settings.maxAge, settings.maxActiveAge),
            ),
          );
        },
      ),
    );
  }
}

class HumanLifePainter extends CustomPainter {
  final int currentAge, maxAge, maxActiveAge;

  const HumanLifePainter(this.currentAge, this.maxAge, this.maxActiveAge);

  /// Weeks per year, counting leap years (because why not).
  /// https://en.wikipedia.org/wiki/ISO_week_date
  ///
  /// Otherwise, this is just 365/7.
  static const weeksPerYear = 52.1775;

  @override
  void paint(Canvas canvas, Size size) {
    final weeks = maxAge * weeksPerYear;

    const minimumSquareArea = 3 * 3;
    const maximumSquareArea = 50 * 50;
    const minColumns = 1;
    const maxColumns = 1000;
    int bestColumns = -1;
    int bestRows = -1;
    for (int columns = minColumns; columns < maxColumns; columns++) {
      final sqArea = (size.height * size.height) / (columns * columns);
      if (minimumSquareArea < sqArea && sqArea < maximumSquareArea) {
        final rows = (weeks / columns).ceil();
        // Trying to find the closest aspect ratio to the one of the viewport.
        final distance = (columns / rows - size.aspectRatio).abs();
        final prevDistance = (bestColumns / bestRows - size.aspectRatio).abs();
        if (bestColumns != -1 && prevDistance < distance) {
          // We've already seen the best ratio. It was the last one.
          break;
        }
        bestColumns = columns;
        bestRows = rows;
      }
    }

    if (bestRows == -1 || bestColumns == -1) {
      // Escape chute.
      bestRows = sqrt(weeks).ceil();
      bestColumns = (weeks / bestRows).ceil();
    }

    final sqSize = (size.height / bestRows).floorToDouble();
    final width = sqSize * bestColumns;
    final leftPadding = (size.width - width) / 2;

    bool currentShownYet = false;
    int week = 0;
    for (int row = 0; row < bestRows; row++) {
      for (int column = 0; column < bestColumns; column++) {
        if (week < weeks) {
          final age = week / weeksPerYear;
          var paint = (age <= currentAge)
              ? lived
              : (age <= maxActiveAge ? active : elderly);
          if (paint == active && !currentShownYet) {
            // The first square in current life.
            paint = current;
            currentShownYet = true;
          }
          final rect = Rect.fromLTWH(leftPadding + column * sqSize,
              row * sqSize, sqSize - 1, sqSize - 1);
          canvas.drawRect(rect, paint);
        }
        week++;
      }
    }
  }

  static final Paint lived = Paint()..color = Color(0xFFB4C5E4);

  static final Paint current = Paint()..color = Colors.white;

  static final Paint active = Paint()..color = Color(0xFF63C132);

  static final Paint elderly = Paint()..color = Color(0xFF358600);

  @override
  bool shouldRepaint(HumanLifePainter old) {
    return currentAge != old.currentAge ||
        maxAge != old.maxAge ||
        maxActiveAge != old.maxActiveAge;
  }
}

class CustomizationDrawer extends StatelessWidget {
  final HumanLifeSettings settings;

  CustomizationDrawer(this.settings);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.15,
      initialChildSize: 0.15,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 0,
              ),
            ],
            color: Theme.of(context).bottomSheetTheme.backgroundColor,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        'Pull up to customize ',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      Icon(Icons.arrow_upward_rounded),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text("What's this about? The app visualizes a human life "
                      "as a series of squares. Each square represents "
                      "a single week of life.\n\n"
                      "Light blue squares are already in the past. "
                      "Light green squares are upcoming active life. "
                      "Dark green squares are the weeks after that.\n\n"
                      "How you define ‘active life’ is up to you.\n\n"
                      "Try to look past the depressing part and instead "
                      "think about this as motivational.\n\n"
                      "Inspired by the article ‘Tail End’ "
                      "at Wait But Why."),
                  SizedBox(height: 32),
                  HumanLifeCustomization(settings),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HumanLifeCustomization extends StatefulWidget {
  final HumanLifeSettings settings;

  const HumanLifeCustomization(this.settings);

  @override
  _HumanLifeCustomizationState createState() => _HumanLifeCustomizationState();
}

class _HumanLifeCustomizationState extends State<HumanLifeCustomization> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AgeSlider(
          label: 'Current age',
          initialValue: widget.settings.currentAge,
          onChanged: (value) => widget.settings.currentAge = value,
        ),
        AgeSlider(
          label: 'Active life expectancy',
          initialValue: widget.settings.maxActiveAge,
          onChanged: (value) => widget.settings.maxActiveAge = value,
        ),
        AgeSlider(
          label: 'Life expectancy',
          initialValue: widget.settings.maxAge,
          onChanged: (value) => widget.settings.maxAge = value,
        ),
      ],
    );
  }
}

class AgeSlider extends StatefulWidget {
  final int initialValue;

  final int maxValue = 100;

  final String label;

  final void Function(int) onChanged;

  const AgeSlider({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  _AgeSliderState createState() => _AgeSliderState();
}

class _AgeSliderState extends State<AgeSlider> {
  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
    _outValue = _value.round();
  }

  double _value = -1;

  int _outValue = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${widget.label}: $_outValue years',
          style: Theme.of(context).textTheme.headline6,
        ),
        Slider(
          value: _value,
          max: widget.maxValue.toDouble(),
          divisions: widget.maxValue,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
            if (_outValue != _value.round()) {
              _outValue = _value.round();
              widget.onChanged(_outValue);
            }
          },
        ),
      ],
    );
  }
}

class HumanLifeSettings extends ChangeNotifier {
  int _currentAge = 18;

  int get currentAge => _currentAge;
  set currentAge(int value) {
    _currentAge = value;
    notifyListeners();
  }

  int _maxAge = 79;

  int get maxAge => _maxAge;
  set maxAge(int value) {
    _maxAge = value;
    notifyListeners();
  }

  int _maxActiveAge = 65;

  int get maxActiveAge => _maxActiveAge;
  set maxActiveAge(int value) {
    _maxActiveAge = value;
    notifyListeners();
  }
}
