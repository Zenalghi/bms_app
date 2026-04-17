import 'package:flutter/material.dart';

class BmsCircularIndicator extends StatelessWidget {
  const BmsCircularIndicator({super.key, required this.soc, required this.soh});

  final double soc;
  final double soh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Gauge(
            label: 'SOC',
            value: soc,
            color: const Color(0xFF00BCD4),
            subtitle: 'State of charge',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _Gauge(
            label: 'SOH',
            value: soh,
            color: const Color(0xFF4CAF50),
            subtitle: 'Health index',
          ),
        ),
      ],
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  final String label;
  final double value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final normalized = (value / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: CircularProgressIndicator(
                  value: normalized,
                  strokeWidth: 12,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
