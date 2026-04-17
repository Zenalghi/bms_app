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
