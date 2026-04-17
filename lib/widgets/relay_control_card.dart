import 'package:flutter/material.dart';

class RelayControlCard extends StatelessWidget {
  const RelayControlCard({
    super.key,
    required this.relayStates,
    required this.onRelayChanged,
  });

  final List<bool> relayStates;
  final void Function(int index, bool value) onRelayChanged;

  @override
  Widget build(BuildContext context) {
    final relays = <_RelayDescriptor>[
      const _RelayDescriptor(name: 'LED Bulb 1', icon: Icons.lightbulb_outline),
      const _RelayDescriptor(name: 'LED Bulb 2', icon: Icons.lightbulb_outline),
      const _RelayDescriptor(name: 'LED Bulb 3', icon: Icons.lightbulb_outline),
      const _RelayDescriptor(name: 'DC Fan', icon: Icons.air),
    ];

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
            'Relay Control',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '2x2 output map for the MQTT-controlled loads',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final relay = relays[index];
              final enabled = relayStates[index];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: enabled
                      ? relay.accentColor.withValues(alpha: 0.14)
                      : const Color(0xFF202020),
                  border: Border.all(
                    color: enabled
                        ? relay.accentColor.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          relay.icon,
                          color: enabled ? relay.accentColor : Colors.white70,
                        ),
                        const Spacer(),
                        Switch.adaptive(
                          value: enabled,
                          activeThumbColor: relay.accentColor,
                          activeTrackColor: relay.accentColor.withValues(
                            alpha: 0.28,
                          ),
                          onChanged: (value) => onRelayChanged(index, value),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          relay.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          enabled ? 'Active' : 'Inactive',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: enabled
                                    ? relay.accentColor
                                    : Colors.white54,
                              ),
                        ),
                      ],
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

class _RelayDescriptor {
  const _RelayDescriptor({required this.name, required this.icon});

  final String name;
  final IconData icon;

  Color get accentColor =>
      icon == Icons.air ? const Color(0xFF64B5F6) : const Color(0xFFFFC107);
}
