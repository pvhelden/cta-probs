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
  // Fixed: always exactly 3 tiles of (0 or 1)
  static const int fixedCount01 = 3;

  // Bounds requested
  static const int maxCount02 = 2; // (0 or 2): 0..2
  static const int maxCount12Light = 4; // (1 or 2) Light: 0..4
  static const int maxCount12Dark = 3; // (1 or 2) Dark: 0..3
  static const int minTarget = 1;
  static const int maxTarget = 20;

  final List<int> count02Options = List.generate(maxCount02 + 1, (i) => i);
  final List<int> count12LightOptions = List.generate(maxCount12Light + 1, (i) => i);
  final List<int> count12DarkOptions = List.generate(maxCount12Dark + 1, (i) => i);
  final List<int> targetOptions = List.generate(maxTarget - minTarget + 1, (i) => minTarget + i);

  // Selections (give sensible defaults to avoid null handling)
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

  /// Exact probability that total >= target
  /// (independent tiles, each 50/50 between its two outcomes)
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

  Widget _dropdown({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((n) => DropdownMenuItem<int>(value: n, child: Text('$n'))).toList(),
      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Optional: keep target within physical bounds if user picks something impossible
    final clampedTarget = target.clamp(1, maxTarget);
    if (clampedTarget != target) {
      // rare, but keep state coherent
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => target = clampedTarget);
      });
    }

    // Compute once for display
    final p = probability;

    return Scaffold(
      appBar: AppBar(title: const Text('Tile Success Probability')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show fixed tiles clearly
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [_FixedChip(label: '0/1 tiles', valueText: '3 (fixed)')],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    label: '0/2 tiles',
                    value: count02,
                    items: count02Options,
                    onChanged: (v) => setState(() => count02 = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    label: 'Target (≥)',
                    value: target,
                    items: targetOptions,
                    onChanged: (v) => setState(() => target = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    label: '1/2 tiles (Light)',
                    value: count12Light,
                    items: count12LightOptions,
                    onChanged: (v) => setState(() => count12Light = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    label: '1/2 tiles (Dark)',
                    value: count12Dark,
                    items: count12DarkOptions,
                    onChanged: (v) => setState(() => count12Dark = v),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              'Possible total range: $minPossibleSum … $maxPossibleSum',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Probability of success', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('${(p * 100).toStringAsFixed(2)}%', style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 6),
                    Text('Success means total ≥ $target', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),

            const Spacer(),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  count02 = 0;
                  count12Light = 0;
                  count12Dark = 0;
                  target = 1;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedChip extends StatelessWidget {
  final String label;
  final String valueText;

  const _FixedChip({required this.label, required this.valueText});

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: const Icon(Icons.lock, size: 18), label: Text('$label: $valueText'));
  }
}
