import 'dart:async';
import 'dart:io';
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
      title: 'JK-BMS Monitor',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const BmsDashboard(),
    );
  }
}

// --- DATA MODEL ---
class BmsState {
  // Sensors
  String totalVoltage = "0.0";
  String current = "0.0";
  String power = "0.0";
  String soc = "0";
  String tempMos = "0.0";
  List<String> cellVoltages = List.filled(8, "0.000"); // 8 Cell BMS

  // BMS Switches
  bool isCharging = false;
  bool isDischarging = false;
  bool isBalancing = false;

  // Relay Control (GPIO) - NEW
  List<bool> relayStates = List.filled(8, false); // 8 Relay

  // Connection
  bool isConnected = false;
}

class BmsDashboard extends StatefulWidget {
  const BmsDashboard({super.key});

  @override
  State<BmsDashboard> createState() => _BmsDashboardState();
}

class _BmsDashboardState extends State<BmsDashboard> {
  final String broker = 'broker.mqtt.cool';
  final int port = 1883;
  // Client ID Unik agar tidak bentrok
  final String clientIdentifier =
      'monitor_${DateTime.now().millisecondsSinceEpoch}';

  // TOPIC UPDATED: skpirsi (Typo disengaja)
  final String topicPrefix = 'skpirsi/bms_unit_1';

  late MqttServerClient client;
  final StreamController<BmsState> _stateController =
      StreamController<BmsState>.broadcast();
  BmsState _currentState = BmsState();

  @override
  void initState() {
    super.initState();
    _connectMqtt();
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
      print('Connecting to $broker...');
      await client.connect();
    } on NoConnectionException catch (e) {
      print('Client exception: $e');
      client.disconnect();
    } on SocketException catch (e) {
      print('Socket exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT Connected');
      setState(() {
        _currentState.isConnected = true;
        _stateController.add(_currentState);
      });

      // Subscribe Wildcard
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
      print('Connection failed');
      client.disconnect();
    }
  }

  void _onDisconnected() {
    print('Disconnected');
    setState(() {
      _currentState.isConnected = false;
      _stateController.add(_currentState);
    });
  }

  void _parseMessage(String topic, String payload) {
    bool updated = false;

    // 1. Main Sensors
    if (topic.endsWith('jk-bms_total_voltage/state')) {
      _currentState.totalVoltage = payload;
      updated = true;
    } else if (topic.endsWith('jk-bms_current/state')) {
      _currentState.current = payload;
      updated = true;
    } else if (topic.endsWith('jk-bms_power/state')) {
      _currentState.power = payload;
      updated = true;
    } else if (topic.endsWith('jk-bms_state_of_charge/state')) {
      _currentState.soc = payload;
      updated = true;
    } else if (topic.endsWith('jk-bms_mos_power_tube_temperature/state')) {
      _currentState.tempMos = payload;
      updated = true;
    }
    // 2. BMS Switches
    else if (topic.endsWith('jk-bms_charging/state')) {
      _currentState.isCharging = (payload == 'ON');
      updated = true;
    } else if (topic.endsWith('jk-bms_discharging/state')) {
      _currentState.isDischarging = (payload == 'ON');
      updated = true;
    } else if (topic.endsWith('jk-bms_balancer/state')) {
      _currentState.isBalancing = (payload == 'ON');
      updated = true;
    }

    // 3. Loop: Cell Voltages (1-8)
    for (int i = 1; i <= 8; i++) {
      if (topic.endsWith('jk-bms_cell_voltage_$i/state')) {
        _currentState.cellVoltages[i - 1] = payload;
        updated = true;
        break;
      }
    }

    // 4. Loop: Relay Controls (1-8) -- NEW
    // Topic format: .../switch/jk-bms_relay_1/state
    for (int i = 1; i <= 8; i++) {
      if (topic.endsWith('jk-bms_relay_$i/state')) {
        _currentState.relayStates[i - 1] = (payload == 'ON');
        updated = true;
        break;
      }
    }

    if (updated) {
      _stateController.add(_currentState);
    }
  }

  // Toggle untuk BMS (Charge/Discharge/Balance)
  void _toggleBmsSwitch(String component, bool value) {
    final String topic = '$topicPrefix/switch/jk-bms_$component/command';
    _publishCommand(topic, value);
  }

  // Toggle untuk Relay GPIO
  void _toggleRelay(int index, bool value) {
    // index 0 -> relay 1
    final int relayNum = index + 1;
    final String topic = '$topicPrefix/switch/jk-bms_relay_$relayNum/command';
    _publishCommand(topic, value);
  }

  void _publishCommand(String topic, bool value) {
    final String payload = value ? "ON" : "OFF";
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print("Pub: $topic -> $payload");
  }

  @override
  void dispose() {
    client.disconnect();
    _stateController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring BMS"),
        actions: [
          StreamBuilder<BmsState>(
            stream: _stateController.stream,
            initialData: _currentState,
            builder: (context, snapshot) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.circle,
                  color: (snapshot.data?.isConnected ?? false)
                      ? Colors.green
                      : Colors.red,
                  size: 14,
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              // --- SECTION 1: BMS UTAMA ---
              _buildMainCard(data),
              const SizedBox(height: 16),

              Text(
                "BMS Control",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlCard(
                    "Charge",
                    data.isCharging,
                    Icons.bolt,
                    (v) => _toggleBmsSwitch('charging', v),
                  ),
                  _buildControlCard(
                    "Discharge",
                    data.isDischarging,
                    Icons.output,
                    (v) => _toggleBmsSwitch('discharging', v),
                  ),
                  _buildControlCard(
                    "Balance",
                    data.isBalancing,
                    Icons.balance,
                    (v) => _toggleBmsSwitch('balancer', v),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // --- PEMBATAS ---
              const Divider(thickness: 2, color: Colors.white24),
              const SizedBox(height: 8),

              // --- SECTION 2: RELAY CONTROL (WIDGET 2 Baris x 4 Kolom) ---
              Text(
                "Cell Monitoring",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[900],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${data.cellVoltages[index]}V",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  );
                },
              ),

              const Divider(thickness: 1, color: Colors.white12),

              // --- SECTION 3: CELL VOLTAGES ---
              Row(
                children: [
                  Icon(Icons.toggle_on, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text(
                    "Relay Control (GPIO)",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // 4 Kolom -> Menghasilkan 2 baris untuk 8 item
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85, // Rasio biar agak tinggi buat tombol
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  final bool isOn = data.relayStates[index];
                  return Material(
                    color: isOn
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _toggleRelay(index, !isOn),
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.power_settings_new,
                            color: isOn ? Colors.orange : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "R${index + 1}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOn ? Colors.white : Colors.white54,
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
      color: Colors.blueAccent.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Voltage",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "${data.totalVoltage} V",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (double.tryParse(data.soc) ?? 0) / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.black26,
                      color: Colors.greenAccent,
                    ),
                    Text(
                      "${data.soc}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  Icons.electric_meter,
                  "${data.current} A",
                  "Arus",
                ),
                _buildMiniStat(Icons.flash_on, "${data.power} W", "Daya"),
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
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
      child: Card(
        color: value
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, color: value ? Colors.greenAccent : Colors.grey),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 12)),
                Switch(
                  padding: EdgeInsets.only(top: 10),
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
