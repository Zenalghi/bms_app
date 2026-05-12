import 'package:flutter/material.dart';

import '../models/bms_state.dart';
import 'analytics_screen.dart';
import 'control_screen.dart';
import 'metrics_screen.dart';
import 'bms_control_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({
    super.key,
    required this.stateStream,
    required this.onRelayToggle,
    required this.onBmsSwitchToggle,
    required this.onBmsNumberSubmit,
    required this.onRefresh,
    required this.onOledPageChange, // <--- TERIMA DARI MAIN
  });

  final Stream<BmsState> stateStream;
  final void Function(int index, bool value) onRelayToggle;
  final void Function(String switchName, bool value) onBmsSwitchToggle;
  final void Function(String settingName, String value) onBmsNumberSubmit;
  final Future<void> Function() onRefresh;
  final void Function(String pagePayload)
  onOledPageChange; // <--- DEKLARASI FUNGSI OLED

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // --- FUNGSI UNTUK MENAMPILKAN POPUP OLED ---
  void _showOledPopup(BuildContext context) {
    final pages = [
      'Main Dashboard',
      'Cell Diagnostics',
      'Environment & Power',
      'Network & System',
      'CELL VOLTAGES',
      'WIRE RESISTOR',
      'PERFORMA SISTEM',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true, // Agar layout menyesuaikan isi
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'OLED Display Remote',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // TOMBOL NEXT PAGE
              ElevatedButton.icon(
                icon: const Icon(Icons.skip_next),
                label: const Text(
                  'NEXT PAGE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(
                    0xFF00BCD4,
                  ).withValues(alpha: 0.2),
                  foregroundColor: const Color(0xFF00BCD4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onOledPageChange('NEXT');
                },
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),

              // LIST 7 HALAMAN SPESIFIK
              ...List.generate(pages.length, (index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    pages[index],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.cast,
                    size: 18,
                    color: Colors.white30,
                  ),
                  onTap: () {
                    // Mengirim payload berupa String angka "1", "2", dst
                    widget.onOledPageChange('${index + 1}');
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
  // -------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BmsState>(
      stream: widget.stateStream,
      initialData: BmsState.initial(),
      builder: (context, snapshot) {
        final state = snapshot.data ?? BmsState.initial();

        return Scaffold(
          // --- TAMBAHKAN APPBAR DI SINI ---
          appBar: AppBar(
            title: const Text(
              'BMS MONITOR & Relay Control',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            actions: [
              // TOMBOL REMOTE OLED DI POJOK KANAN ATAS
              IconButton(
                icon: const Icon(
                  Icons.cast_connected,
                  color: Color.fromARGB(255, 0, 188, 212),
                ),
                tooltip: 'OLED Remote Control',
                onPressed: () => _showOledPopup(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                MetricsScreen(state: state, onRefresh: widget.onRefresh),
                BmsControlScreen(
                  state: state,
                  onBmsSwitchToggle: widget.onBmsSwitchToggle,
                  onBmsNumberSubmit: widget.onBmsNumberSubmit,
                  onRefresh: widget.onRefresh,
                ),
                AnalyticsScreen(),
                ControlScreen(
                  state: state,
                  onRelayToggle: widget.onRelayToggle,
                  onRefresh: widget.onRefresh,
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            height: 72,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.bolt_outlined),
                selectedIcon: Icon(Icons.bolt),
                label: 'Metrics',
              ),
              NavigationDestination(
                icon: Icon(Icons.battery_charging_full_outlined),
                selectedIcon: Icon(Icons.battery_charging_full),
                label: 'BMS',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'Data Cloud',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_remote_outlined),
                selectedIcon: Icon(Icons.settings_remote),
                label: 'Relays',
              ),
            ],
          ),
        );
      },
    );
  }
}
