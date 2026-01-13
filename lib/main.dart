import 'package:flutter/material.dart';

void main() => runApp(const ProbApp());

class ProbApp extends StatelessWidget {
  const ProbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tile Success Probability',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
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
  // Dropdown ranges for counts. Adjust as you like.
  static const int maxCount = 20;
  final List<int> countOptions = List.generate(maxCount + 1, (i) => i); // 0..20

  int? count01; // tiles that are 0 or 1
  int? count02; // tiles that are 0 or 2
  int? count12; // tiles that are 1 or 2
  int? target; // minimum target

  double? probability;

  int _maxPossibleSum(int a, int b, int c) => a * 1 + b * 2 + c * 2;

  int _minPossibleSum(int a, int b, int c) => a * 0 + b * 0 + c * 1;

  List<int> _targetOptionsForCurrentCounts() {
    if (count01 == null || count02 == null || count12 == null) {
      // fallback range if not selected yet
      return List.generate(41, (i) => i); // 0..40
    }
    final a = count01!, b = count02!, c = count12!;
    final minS = _minPossibleSum(a, b, c);
    final maxS = _maxPossibleSum(a, b, c);
    return List.generate(maxS - minS + 1, (i) => minS + i);
  }

  void _recomputeIfReady() {
    if (count01 == null || count02 == null || count12 == null || target == null) {
      setState(() => probability = null);
      return;
    }

    final a = count01!;
    final b = count02!;
    final c = count12!;
    final t = target!;

    final p = probabilityAtLeastTarget(count01: a, count02: b, count12: c, target: t);

    setState(() => probability = p);
  }

  /// Exact probability that total >= target
  /// Tiles are independent and each is 50/50 between its two outcomes:
  /// - 0/1, 0/2, 1/2
  double probabilityAtLeastTarget({
    required int count01,
    required int count02,
    required int count12,
    required int target,
  }) {
    // dp[sum] = probability of achieving exactly `sum`
    List<double> dp = [1.0];

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

    // Add count01 tiles of {0,1}
    convolveFairTwoPoint(0, 1, count01);
    // Add count02 tiles of {0,2}
    convolveFairTwoPoint(0, 2, count02);
    // Add count12 tiles of {1,2}
    convolveFairTwoPoint(1, 2, count12);

    double success = 0.0;
    for (int s = 0; s < dp.length; s++) {
      if (s >= target) success += dp[s];
    }
    return success;
  }

  Widget _dropdown({
    required String label,
    required int? value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((n) => DropdownMenuItem<int>(value: n, child: Text('$n'))).toList(),
      onChanged: (v) {
        onChanged(v);
        _recomputeIfReady();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final targets = _targetOptionsForCurrentCounts();

    final statusText = () {
      if (probability == null) return 'Select all 4 values to compute probability.';
      return 'Probability of success: ${(probability! * 100).toStringAsFixed(2)}%';
    }();

    final hintText = () {
      if (count01 == null || count02 == null || count12 == null) return '';
      final a = count01!, b = count02!, c = count12!;
      final minS = _minPossibleSum(a, b, c);
      final maxS = _maxPossibleSum(a, b, c);
      return 'Possible total range: $minS … $maxS';
    }();

    return Scaffold(
      appBar: AppBar(title: const Text('Tile Success Probability')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    label: 'Count of (0 or 1)',
                    value: count01,
                    items: countOptions,
                    onChanged: (v) {
                      setState(() {
                        count01 = v;
                        // If target becomes invalid, clear it.
                        if (target != null && count01 != null && count02 != null && count12 != null) {
                          final minS = _minPossibleSum(count01!, count02!, count12!);
                          final maxS = _maxPossibleSum(count01!, count02!, count12!);
                          if (target! < minS || target! > maxS) target = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    label: 'Count of (0 or 2)',
                    value: count02,
                    items: countOptions,
                    onChanged: (v) {
                      setState(() {
                        count02 = v;
                        if (target != null && count01 != null && count02 != null && count12 != null) {
                          final minS = _minPossibleSum(count01!, count02!, count12!);
                          final maxS = _maxPossibleSum(count01!, count02!, count12!);
                          if (target! < minS || target! > maxS) target = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    label: 'Count of (1 or 2)',
                    value: count12,
                    items: countOptions,
                    onChanged: (v) {
                      setState(() {
                        count12 = v;
                        if (target != null && count01 != null && count02 != null && count12 != null) {
                          final minS = _minPossibleSum(count01!, count02!, count12!);
                          final maxS = _maxPossibleSum(count01!, count02!, count12!);
                          if (target! < minS || target! > maxS) target = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    label: 'Target (min total)',
                    value: target,
                    items: targets,
                    onChanged: (v) => setState(() => target = v),
                  ),
                ),
              ],
            ),

            if (hintText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(hintText, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],

            const SizedBox(height: 18),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.assessment),
                    const SizedBox(width: 12),
                    Expanded(child: Text(statusText, style: Theme.of(context).textTheme.titleMedium)),
                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                onPressed: () {
                  setState(() {
                    count01 = null;
                    count02 = null;
                    count12 = null;
                    target = null;
                    probability = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
