import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bms_state.dart';

class RelayControlCard extends StatelessWidget {
  const RelayControlCard({
    super.key,
    required this.relayStates,
    required this.onRelayChanged,
    required this.state, // Kita butuh full state untuk ambil logs & ms
  });

  final List<bool> relayStates;
  final void Function(int index, bool value) onRelayChanged;
  final BmsState state;

  Future<void> _exportCSV(BuildContext context) async {
    if (state.relayLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data pengujian untuk diekspor.'),
        ),
      );
      return;
    }

    try {
      // 1. Buat Header CSV
      StringBuffer sb = StringBuffer();
      sb.writeln("No,Relay Target,Command (ON/OFF),Response Time (ms)");

      // 2. Isi Data CSV
      for (int i = 0; i < state.relayLogs.length; i++) {
        final log = state.relayLogs[i];
        sb.writeln(
          "${i + 1},Relay ${log.relayIndex + 1},${log.command},${log.responseMs}",
        );
      }

      // 3. Simpan ke storage sementara
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/skripsi_relay_test_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(sb.toString());

      // 4. Buka menu Share (WhatsApp, Email, dll)
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Data Pengujian Kecepatan Respons Relay (Skripsi)');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Relay Control & Test',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              // Total Counter Seluruh Log
              Text(
                'Total Data: ${state.relayLogs.length}',
                style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tekan switch untuk menguji Response Time aktuator.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relays.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final relay = relays[index];
              final enabled = relayStates[index];

              // Ambil metrics data
              final int? onMs = state.latestOnMs[index];
              final int? offMs = state.latestOffMs[index];
              final int logCount = state.relayLogs
                  .where((log) => log.relayIndex == index)
                  .length;

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

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            relay.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          // METRIK RESPONSE TIME UI
                          Text(
                            'ON: ${onMs != null ? '$onMs ms' : '-'}  |  OFF: ${offMs != null ? '$offMs ms' : '-'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: enabled
                                  ? relay.accentColor
                                  : Colors.white70,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Counter: $logCount/50',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),

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

          const SizedBox(height: 24),
          // TOMBOL SHARE CSV
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.ios_share, size: 18),
              label: const Text(
                'Share CSV Data Pengujian',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => _exportCSV(context),
            ),
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
  Color get accentColor => const Color(0xFF00BCD4);
}
