import 'package:flutter/material.dart';

import '../models/bms_state.dart';
import '../widgets/relay_control_card.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({
    super.key,
    required this.state,
    required this.onRelayToggle,
  });

  final BmsState state;
  final void Function(int index, bool value) onRelayToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Hardware Control',
            subtitle: 'Relay outputs and real-time connectivity status',
          ),
          const SizedBox(height: 16),

          // Row Indikator Status (Koneksi & Balancer)
          // _ConnectivityRow(state: state),
          const SizedBox(height: 16),

          // Card Kontrol Relay
          RelayControlCard(
            relayStates: state.relayStates,
            onRelayChanged: onRelayToggle,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _ConnectivityRow extends StatelessWidget {
  const _ConnectivityRow({required this.state});

  final BmsState state;

  @override
  Widget build(BuildContext context) {
    // Indikator Online: Jika tegangan terbaca > 0, dianggap data sudah masuk
    final bool isBmsOnline = state.totalVoltage > 0;

    // Indikator Balancer: Membaca status balancing langsung dari BMS
    final bool isBalancing = state.isBalancing;

    return Row(
      children: [
        Expanded(
          child: _StatusPill(
            label: isBmsOnline ? 'BMS LINKED' : 'WAITING DATA',
            color: isBmsOnline
                ? const Color(0xFF4CAF50)
                : const Color(0xFFD32F2F),
            isActive: isBmsOnline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusPill(
            label: isBalancing ? 'BALANCING ON' : 'BAL. STANDBY',
            color: isBalancing ? const Color(0xFFFFC107) : Colors.white30,
            isActive: isBalancing,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.isActive,
  });

  final String label;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isActive ? color : Colors.white54,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
