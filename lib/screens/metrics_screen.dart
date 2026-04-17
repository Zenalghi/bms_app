import 'package:flutter/material.dart';
import '../models/bms_state.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key, required this.state});

  final BmsState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan indikator status Online/Offline MQTT
          _SectionHeader(
            title: 'Electrical Metrics',
            subtitle: 'Real-time power and battery health monitoring',
            status: state.bmsStatus,
          ),
          const SizedBox(height: 16),

          // Kartu Utama (Total Voltage, Current, Power, Temps, Capacity)
          _TotalVoltageCard(state: state),

          const SizedBox(height: 16),

          // Grid Cell Voltages (4x2)
          _SmallGridCard(
            title: 'Cell Voltages',
            values: state.cellVoltages,
            unit: 'V',
            decimal: 3,
            color: const Color(0xFF00BCD4),
          ),

          const SizedBox(height: 16),

          // Grid Wire Resistance (4x2)
          _SmallGridCard(
            title: 'Wire Resistance',
            values: state.wireRes,
            unit: 'mΩ',
            decimal: 3,
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    final bool isOnline = status.toLowerCase() == 'online';
    final Color statusColor = isOnline
        ? const Color(0xFF4CAF50)
        : const Color(0xFFD32F2F);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        // Indikator Status MQTT
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isOnline)
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalVoltageCard extends StatelessWidget {
  const _TotalVoltageCard({required this.state});

  final BmsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Voltage',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              _StatusIndicator(state: state),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${state.totalVoltage.toStringAsFixed(2)} V',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Current',
                  value: '${state.current.toStringAsFixed(1)} A',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  label: 'Power',
                  value: '${state.power.toStringAsFixed(1)} W',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  label: 'Capacity',
                  value: '${state.capacityRemain.toStringAsFixed(1)} Ah',
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'MOS Temp',
                  value: '${state.tempMos.toStringAsFixed(1)}°C',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  label: 'Bat T1',
                  value: '${state.batTemp1.toStringAsFixed(1)}°C',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  label: 'Bat T2',
                  value: '${state.batTemp2.toStringAsFixed(1)}°C',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.state});
  final BmsState state;

  @override
  Widget build(BuildContext context) {
    String label = 'Idle';
    Color color = Colors.white30;

    if (state.current > 0.1) {
      label = 'Charging';
      color = const Color(0xFF4CAF50);
    } else if (state.current < -0.1) {
      label = 'Discharging';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _SmallGridCard extends StatelessWidget {
  const _SmallGridCard({
    required this.title,
    required this.values,
    required this.unit,
    required this.decimal,
    required this.color,
  });

  final String title;
  final List<double> values;
  final String unit;
  final int decimal;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white30,
                      ),
                    ),
                    Text(
                      values[index].toStringAsFixed(decimal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
