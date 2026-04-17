import 'package:flutter/material.dart';
import '../models/bms_state.dart';

class BmsControlScreen extends StatelessWidget {
  const BmsControlScreen({
    super.key,
    required this.state,
    required this.onBmsSwitchToggle,
    required this.onBmsNumberSubmit,
  });

  final BmsState state;
  final void Function(String switchName, bool value) onBmsSwitchToggle;
  final void Function(String settingName, String value) onBmsNumberSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BMS Internal Control',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage Jikong BMS parameters and protections',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 24),

          // BMS STATUS PILL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: state.bmsStatus == 'online'
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.bmsStatus == 'online' ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi,
                  color: state.bmsStatus == 'online'
                      ? Colors.green
                      : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'BMS ${state.bmsStatus.toUpperCase()}',
                  style: TextStyle(
                    color: state.bmsStatus == 'online'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SWITCHES CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protection Switches',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const Divider(color: Colors.white10, height: 30),
                _BmsSwitchRow(
                  label: 'Charge Switch',
                  isActive: state.isCharging,
                  color: Colors.green,
                  onChanged: (v) => onBmsSwitchToggle('charge', v),
                ),
                const SizedBox(height: 12),
                _BmsSwitchRow(
                  label: 'Discharge Switch',
                  isActive: state.isDischarging,
                  color: Colors.orange,
                  onChanged: (v) => onBmsSwitchToggle('discharge', v),
                ),
                const SizedBox(height: 12),
                _BmsSwitchRow(
                  label: 'Balance Switch',
                  isActive: state.isBalancing,
                  color: Colors.blue,
                  onChanged: (v) => onBmsSwitchToggle('balance', v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SETTINGS CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hardware Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const Divider(color: Colors.white10, height: 30),
                _BmsNumberRow(
                  context: context,
                  label: 'Cell Count',
                  value: state.cellCountSetting.toString(),
                  unit: 'S',
                  topicKey: 'cell_count_setting',
                  onSubmit: onBmsNumberSubmit,
                ),
                const Divider(color: Colors.white10, height: 24),
                _BmsNumberRow(
                  context: context,
                  label: 'Capacity',
                  value: state.capacitySetting.toStringAsFixed(1),
                  unit: 'Ah',
                  topicKey: 'capacity_setting',
                  onSubmit: onBmsNumberSubmit,
                ),
                const Divider(color: Colors.white10, height: 24),
                _BmsNumberRow(
                  context: context,
                  label: 'Bal. Trigger',
                  value: state.balanceTrigV.toStringAsFixed(3),
                  unit: 'V',
                  topicKey: 'balance_trig_v',
                  onSubmit: onBmsNumberSubmit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BmsSwitchRow extends StatelessWidget {
  const _BmsSwitchRow({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onChanged,
  });
  final String label;
  final bool isActive;
  final Color color;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.power_settings_new,
              color: isActive ? color : Colors.white30,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        Switch.adaptive(
          value: isActive,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _BmsNumberRow extends StatelessWidget {
  const _BmsNumberRow({
    required this.context,
    required this.label,
    required this.value,
    required this.unit,
    required this.topicKey,
    required this.onSubmit,
  });
  final BuildContext context;
  final String label;
  final String value;
  final String unit;
  final String topicKey;
  final Function(String, String) onSubmit;

  void _showEditDialog() {
    final TextEditingController ctrl = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: Text('Set $label'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              onSubmit(topicKey, ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        InkWell(
          onTap: _showEditDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  '$value $unit',
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 14, color: Colors.cyan),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
