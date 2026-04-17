import 'package:flutter/material.dart';

import '../models/bms_state.dart';
// import 'analytics_screen.dart';
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
    required this.onRefresh, // <--- TERIMA DARI MAIN
  });

  final Stream<BmsState> stateStream;
  final void Function(int index, bool value) onRelayToggle;
  final void Function(String switchName, bool value) onBmsSwitchToggle;
  final void Function(String settingName, String value) onBmsNumberSubmit;
  final Future<void> Function() onRefresh; // <--- DEKLARASI FUNGSI

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BmsState>(
      stream: widget.stateStream,
      initialData: BmsState.initial(),
      builder: (context, snapshot) {
        final state = snapshot.data ?? BmsState.initial();

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                MetricsScreen(
                  state: state,
                  onRefresh: widget.onRefresh, // <--- OPER KE METRICS SCREEN
                ),
                // AnalyticsScreen(state: state),
                BmsControlScreen(
                  state: state,
                  onBmsSwitchToggle: widget.onBmsSwitchToggle,
                  onBmsNumberSubmit: widget.onBmsNumberSubmit,
                ),
                ControlScreen(
                  state: state,
                  onRelayToggle: widget.onRelayToggle,
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
              // NavigationDestination(
              //   icon: Icon(Icons.analytics_outlined),
              //   selectedIcon: Icon(Icons.analytics),
              //   label: 'Analytics',
              // ),
              NavigationDestination(
                icon: Icon(Icons.battery_charging_full_outlined),
                selectedIcon: Icon(Icons.battery_charging_full),
                label: 'BMS',
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
