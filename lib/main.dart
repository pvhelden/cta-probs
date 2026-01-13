import 'package:cta_probs/widgets/labeled_dropdown.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ProbApp());

class ProbApp extends StatelessWidget {
  const ProbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runes Success Probability',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Tangerine',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
          ),
        ),
        cardTheme: CardThemeData(color: Colors.white.withValues(alpha: 0.7)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.7),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const ProbHome(),
    );
  }
}

class ProbHome extends StatefulWidget {
  const ProbHome({super.key});

  @override
  State<ProbHome> createState() => _ProbHomeState();
}

class _ProbHomeState extends State<ProbHome> {
  static const int fixedCount01 = 3;

  static const int maxCount02 = 2; // (0 or 2): 0..2
  static const int maxCount12Light = 4; // (1 or 2) Light: 0..4
  static const int maxCount12Dark = 3; // (1 or 2) Dark: 0..3
  static const int minTarget = 1;
  static const int maxTarget = 20;

  final List<int> count02Options = List.generate(maxCount02 + 1, (i) => i);
  final List<int> count12LightOptions = List.generate(maxCount12Light + 1, (i) => i);
  final List<int> count12DarkOptions = List.generate(maxCount12Dark + 1, (i) => i);
  final List<int> targetOptions = List.generate(maxTarget - minTarget + 1, (i) => minTarget + i);

  int count02 = 0;
  int count12Light = 0;
  int count12Dark = 0;
  int target = 1;

  double get probability => probabilityAtLeastTarget(
    count01: fixedCount01,
    count02: count02,
    count12: count12Light + count12Dark,
    target: target,
  );

  int get minPossibleSum => fixedCount01 * 0 + count02 * 0 + (count12Light + count12Dark) * 1;

  int get maxPossibleSum => fixedCount01 * 1 + count02 * 2 + (count12Light + count12Dark) * 2;

  double probabilityAtLeastTarget({
    required int count01, // tiles: {0,1}
    required int count02, // tiles: {0,2}
    required int count12, // tiles: {1,2}
    required int target,
  }) {
    List<double> dp = [1.0]; // dp[sum] = P(total == sum)

    void convolveFairTwoPoint(int v1, int v2, int times) {
      for (int k = 0; k < times; k++) {
        final next = List<double>.filled(dp.length + v2, 0.0);
        for (int s = 0; s < dp.length; s++) {
          final p = dp[s];
          next[s + v1] += 0.5 * p;
          next[s + v2] += 0.5 * p;
        }
        dp = next;
      }
    }

    convolveFairTwoPoint(0, 1, count01);
    convolveFairTwoPoint(0, 2, count02);
    convolveFairTwoPoint(1, 2, count12);

    double success = 0.0;
    for (int s = 0; s < dp.length; s++) {
      if (s >= target) success += dp[s];
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    final clampedTarget = target.clamp(1, maxTarget);
    if (clampedTarget != target) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => target = clampedTarget);
      });
    }

    final p = probability;

    return Scaffold(
      appBar: AppBar(title: const Text('Runes Success Probability'), centerTitle: true),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('Base Runes: $fixedCount01', style: Theme.of(context).textTheme.titleSmall),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: LabeledDropdown<int>(
                        title: 'Ability Runes',
                        value: count12Light,
                        items: count12LightOptions.map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                        onChanged: (v) => setState(() => count12Light = v ?? 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledDropdown<int>(
                        title: 'Special Ability Runes',
                        value: count02,
                        items: count02Options.map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                        onChanged: (v) => setState(() => count02 = v ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LabeledDropdown<int>(
                        title: 'Dark Runes',
                        value: count12Dark,
                        items: count12DarkOptions.map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                        onChanged: (v) => setState(() => count12Dark = v ?? 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledDropdown<int>(
                        title: 'Difficulty',
                        value: target,
                        items: targetOptions.map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                        onChanged: (v) => setState(() => target = v ?? 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Probability of success', style: Theme.of(context).textTheme.titleMedium),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${(p * 100).toStringAsFixed(2)}%',
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Min: $minPossibleSum',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Max: $maxPossibleSum',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
