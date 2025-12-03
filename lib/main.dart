import 'dart:async';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JK-BMS Energy Monitor',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.cyan,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const BmsDashboard(),
    );
  }
}

// --- DATA MODEL ---
class BmsState {
  // Sensors
  String totalVoltage = "0.000"; // Default 3 decimals
  String current = "0.0";
  String power = "0.0";
  String soc = "0";
  String tempMos = "0.0";
  List<String> cellVoltages = List.filled(8, "0.000");

  // BMS Switches
  bool isCharging = false;
  bool isDischarging = false;
  bool isBalancing = false;

  // Relay Control (GPIO)
  List<bool> relayStates = List.filled(8, false);

  // Connection & System Status
  bool isMqttConnected = false;
  String deviceStatus = "offline";
}

class BmsDashboard extends StatefulWidget {
  const BmsDashboard({super.key});

  @override
  State<BmsDashboard> createState() => _BmsDashboardState();
}

class _BmsDashboardState extends State<BmsDashboard> {
  final String broker = 'broker.mqtt.cool';
  final int port = 1883;
  final String clientIdentifier =
      'energy_monitor_${DateTime.now().millisecondsSinceEpoch}';

  // Topik sesuai konfigurasi YAML baru
  final String topicPrefix = 'energy/bms_monitor';

  late MqttServerClient client;
  final StreamController<BmsState> _stateController =
      StreamController<BmsState>.broadcast();
  BmsState _currentState = BmsState();

  @override
  void initState() {
    super.initState();
    _connectMqtt();
  }

  // --- HELPER FORMATTING ANGKA ---
  // Fungsi ini memastikan angka tampil sesuai keinginan (3 digit atau 1 digit)
  String _formatValue(String value, int decimalPlaces) {
    double? v = double.tryParse(value);
    if (v == null) return value; // Jika error/bukan angka, kembalikan aslinya
    return v.toStringAsFixed(decimalPlaces);
  }

  Future<void> _connectMqtt() async {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT Connected');
      setState(() {
        _currentState.isMqttConnected = true;
        _stateController.add(_currentState);
      });

      client.subscribe('$topicPrefix/#', MqttQos.atMostOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String topic = c[0].topic;
        final String payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        _parseMessage(topic, payload);
      });
    } else {
      client.disconnect();
    }
  }

  void _onDisconnected() {
    setState(() {
      _currentState.isMqttConnected = false;
      _stateController.add(_currentState);
    });
  }

  void _parseMessage(String topic, String payload) {
    bool updated = false;

    // 1. SYSTEM STATUS
    if (topic == '$topicPrefix/status') {
      _currentState.deviceStatus = payload;
      updated = true;
    }
    // 2. Main Sensors
    else if (topic.endsWith('jk-bms_total_voltage/state')) {
      // REQUIREMENT: Tegangan 3 Digit
      _currentState.totalVoltage = _formatValue(payload, 3);
      updated = true;
    } else if (topic.endsWith('jk-bms_current/state')) {
      // REQUIREMENT: Arus 1 Digit
      _currentState.current = _formatValue(payload, 1);
      updated = true;
    } else if (topic.endsWith('jk-bms_power/state')) {
      // REQUIREMENT: Power 1 Digit
      _currentState.power = _formatValue(payload, 1);
      updated = true;
    } else if (topic.endsWith('jk-bms_state_of_charge/state')) {
      _currentState.soc = payload.split('.').first; // SoC ambil bulat saja
      updated = true;
    } else if (topic.endsWith('jk-bms_mos_temp/state') ||
        topic.endsWith('jk-bms_mos_power_tube_temperature/state')) {
      // REQUIREMENT: Temp 1 Digit
      _currentState.tempMos = _formatValue(payload, 1);
      updated = true;
    }
    // 3. BMS Switches
    else if (topic.endsWith('jk-bms_charging_switch/state')) {
      _currentState.isCharging = (payload == 'ON');
      updated = true;
    } else if (topic.endsWith('jk-bms_discharging_switch/state')) {
      _currentState.isDischarging = (payload == 'ON');
      updated = true;
    } else if (topic.endsWith('jk-bms_balancer_switch/state')) {
      _currentState.isBalancing = (payload == 'ON');
      updated = true;
    }
    // 4. Cell Voltages & Relay
    else {
      // UPDATE PARSING: "jk-bms_cell_$i" (Sesuai YAML baru)
      for (int i = 1; i <= 8; i++) {
        if (topic.endsWith('jk-bms_cell_$i/state')) {
          _currentState.cellVoltages[i - 1] = _formatValue(
            payload,
            3,
          ); // Cell juga 3 digit
          updated = true;
          break;
        }
      }

      for (int i = 1; i <= 8; i++) {
        if (topic.endsWith('load_control_$i/state')) {
          _currentState.relayStates[i - 1] = (payload == 'ON');
          updated = true;
          break;
        }
      }
    }

    if (updated) {
      _stateController.add(_currentState);
    }
  }

  void _toggleBmsSwitch(String component, bool value) {
    final String topic = '$topicPrefix/switch/jk-bms_$component/command';
    _publishCommand(topic, value);
  }

  void _toggleRelay(int index, bool value) {
    final int relayNum = index + 1;
    final String topic = '$topicPrefix/switch/load_control_$relayNum/command';
    _publishCommand(topic, value);
  }

  void _publishCommand(String topic, bool value) {
    final String payload = value ? "ON" : "OFF";
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  @override
  void dispose() {
    client.disconnect();
    _stateController.close();
    super.dispose();
  }

  // --- UI WIDGETS ---

  Color _getStatusColor(String status) {
    if (status == 'online') return Colors.greenAccent;
    if (status == 'searching_device') return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getStatusText(String status) {
    if (status == 'online') return "Connected";
    if (status == 'searching_device') return "Scanning...";
    return "Offline";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Energy Monitor"),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          StreamBuilder<BmsState>(
            stream: _stateController.stream,
            initialData: _currentState,
            builder: (context, snapshot) {
              final data = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Chip(
                  avatar: Icon(
                    Icons.circle,
                    color: _getStatusColor(data.deviceStatus),
                    size: 12,
                  ),
                  label: Text(
                    _getStatusText(data.deviceStatus),
                    style: TextStyle(
                      color: _getStatusColor(data.deviceStatus),
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: Colors.black54,
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<BmsState>(
        stream: _stateController.stream,
        initialData: _currentState,
        builder: (context, snapshot) {
          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // 1. MAIN METRICS
              _buildMainCard(data),

              const SizedBox(height: 20),

              // 2. CELL VOLTAGE MONITORING (POSISI DIPINDAH KESINI)
              Text(
                "Cell Voltage Monitoring",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2.2, // Sedikit lebih pipih agar compact
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${data.cellVoltages[index]} V",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),

              // const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              // const SizedBox(height: 16),

              // 3. BMS CONTROL
              Text(
                "BMS Protection",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildControlCard(
                    "Charge",
                    data.isCharging,
                    Icons.bolt,
                    (v) => _toggleBmsSwitch('charging_switch', v),
                  ),
                  _buildControlCard(
                    "Discharge",
                    data.isDischarging,
                    Icons.output,
                    (v) => _toggleBmsSwitch('discharging_switch', v),
                  ),
                  _buildControlCard(
                    "Balance",
                    data.isBalancing,
                    Icons.balance,
                    (v) => _toggleBmsSwitch('balancer_switch', v),
                  ),
                ],
              ),

              const SizedBox(height: 13),
              const Divider(color: Colors.white10),
              // const SizedBox(height: 16),

              // 4. LOAD CONTROL (RELAYS)
              Row(
                children: [
                  const Icon(Icons.toggle_on, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  Text(
                    "Smart Load Control",
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  final bool isOn = data.relayStates[index];
                  return Material(
                    color: isOn
                        ? Colors.cyan.withOpacity(0.2)
                        : const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _toggleRelay(index, !isOn),
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.power_settings_new,
                            color: isOn ? Colors.cyanAccent : Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Load ${index + 1}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: isOn ? Colors.white : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainCard(BmsState data) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan.withOpacity(0.15),
              Colors.blue.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TOTAL VOLTAGE",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // FORMAT 3 DIGIT
                    Text(
                      "${data.totalVoltage} V",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: CircularProgressIndicator(
                        value: (double.tryParse(data.soc) ?? 0) / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white10,
                        color: Colors.greenAccent,
                      ),
                    ),
                    Text(
                      "${data.soc}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // FORMAT 1 DIGIT (Sesuai helper)
                _buildMiniStat(
                  Icons.electric_meter,
                  "${data.current} A",
                  "Current",
                ),
                Container(width: 1, height: 30, color: Colors.white10),
                _buildMiniStat(Icons.flash_on, "${data.power} W", "Power"),
                Container(width: 1, height: 30, color: Colors.white10),
                _buildMiniStat(Icons.thermostat, "${data.tempMos}°C", "Temp"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey[400], size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildControlCard(
    String title,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF1B3A2D) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? Colors.green.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: value ? Colors.greenAccent : Colors.grey,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: value ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 24,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: Colors.greenAccent,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
