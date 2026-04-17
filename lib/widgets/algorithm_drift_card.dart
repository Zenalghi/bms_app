import 'package:flutter/material.dart';

class AlgorithmDriftCard extends StatelessWidget {
  const AlgorithmDriftCard({
    super.key,
    required this.socEKF,
    required this.socCC,
  });

  final double socEKF;
  final double socCC;

  @override
  Widget build(BuildContext context) {
    final mean = (socEKF + socCC) / 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Algorithm Drift',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Compare EKF and Coulomb Counting only',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          _DriftRow(
            label: 'EKF',
            value: socEKF,
            drift: socEKF - mean,
            color: const Color(0xFF00BCD4),
          ),
          const SizedBox(height: 14),
          _DriftRow(
            label: 'CC',
            value: socCC,
            drift: socCC - mean,
            color: const Color(0xFFFFC107),
          ),
        ],
      ),
    );
  }
}

class _DriftRow extends StatelessWidget {
  const _DriftRow({
    required this.label,
    required this.value,
    required this.drift,
    required this.color,
  });

  final String label;
  final double value;
  final double drift;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = (value / 100).clamp(0.0, 1.0);
    final driftText = drift >= 0
        ? '+${drift.toStringAsFixed(2)}%'
        : '${drift.toStringAsFixed(2)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${value.toStringAsFixed(1)}%  ($driftText)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: normalized,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
