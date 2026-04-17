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
    // Label dan ikon dibuat umum untuk keperluan hardware relay
    final relays = <_RelayDescriptor>[
      const _RelayDescriptor(
        name: 'Relay Output 1',
        icon: Icons.settings_input_component,
      ),
      const _RelayDescriptor(
        name: 'Relay Output 2',
        icon: Icons.settings_input_component,
      ),
      const _RelayDescriptor(
        name: 'Relay Output 3',
        icon: Icons.settings_input_component,
      ),
      const _RelayDescriptor(
        name: 'Relay Output 4',
        icon: Icons.settings_input_component,
      ),
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
            '4-channel output map for MQTT-controlled loads',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),

          // Diubah dari GridView menjadi ListView untuk susunan 1x4 ke bawah
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relays.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final relay = relays[index];
              final enabled = relayStates[index];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: enabled
                      ? relay.accentColor.withValues(alpha: 0.14)
                      : const Color(0xFF202020),
                  border: Border.all(
                    color: enabled
                        ? relay.accentColor.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    // Ikon diletakkan di dalam lingkaran agar lebih rapi
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: enabled
                            ? relay.accentColor.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        relay.icon,
                        color: enabled ? relay.accentColor : Colors.white70,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Teks diletakkan di tengah
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            relay.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
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
                    ),

                    // Switch diletakkan di ujung kanan
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

  // Menggunakan warna Cyan standar aplikasi untuk semua relay
  Color get accentColor => const Color(0xFF00BCD4);
}
