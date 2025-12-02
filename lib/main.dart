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
        brightness: Brightness.dark, // Tema gelap biar keren ala dashboard
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
  List<String> cellVoltages = List.filled(8, "0.000"); // 8 Sel

  // Switches (Status)
  bool isCharging = false;
  bool isDischarging = false;
  bool isBalancing = false;

  // Connection
  bool isConnected = false;
}

class BmsDashboard extends StatefulWidget {
  const BmsDashboard({super.key});

  @override
  State<BmsDashboard> createState() => _BmsDashboardState();
}

class _BmsDashboardState extends State<BmsDashboard> {
  // Konfigurasi MQTT sesuai YAML
  final String broker = 'broker.mqtt.cool';
  final int port = 1883;
  final String clientIdentifier =
      'monitor_${DateTime.now().millisecondsSinceEpoch}';
  final String topicPrefix = 'skripsi/bms_unit_1';

  late MqttServerClient client;

  // Stream controller untuk update UI Realtime
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

    // Config message connection
    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean() // Non persistent session
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

      // Subscribe ke semua topic di bawah prefix (Wildcard #)
      // Ini menangkap sensor dan status switch
      client.subscribe('$topicPrefix/#', MqttQos.atMostOnce);

      // Listener Pesan Masuk
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

  // --- PARSING DATA DARI ESPHOME ---
  void _parseMessage(String topic, String payload) {
    // Mapping topic string ke variable state
    // Contoh topic: skripsi/bms_unit_1/sensor/jk-bms_total_voltage/state

    // Perbaikan logic: Cek akhiran topic agar lebih aman
    if (topic.endsWith('jk-bms_total_voltage/state')) {
      _currentState.totalVoltage = payload;
    } else if (topic.endsWith('jk-bms_current/state')) {
      _currentState.current = payload;
    } else if (topic.endsWith('jk-bms_power/state')) {
      _currentState.power = payload;
    } else if (topic.endsWith('jk-bms_state_of_charge/state')) {
      _currentState.soc = payload;
    } else if (topic.endsWith('jk-bms_mos_power_tube_temperature/state')) {
      _currentState.tempMos = payload;
    }
    // Switch Status (Feedback dari alat)
    else if (topic.endsWith('jk-bms_charging/state')) {
      _currentState.isCharging = (payload == 'ON');
    } else if (topic.endsWith('jk-bms_discharging/state')) {
      _currentState.isDischarging = (payload == 'ON');
    } else if (topic.endsWith('jk-bms_balancer/state')) {
      _currentState.isBalancing = (payload == 'ON');
    }
    // Cell Voltages (Looping check)
    else {
      for (int i = 1; i <= 8; i++) {
        if (topic.endsWith('jk-bms_cell_voltage_$i/state')) {
          _currentState.cellVoltages[i - 1] = payload;
          break;
        }
      }
    }

    // Push update ke UI
    _stateController.add(_currentState);
  }

  // --- FUNGSI KONTROL (PUBLISH) ---
  void _toggleSwitch(String component, bool value) {
    // component: 'charging', 'discharging', 'balancer'
    // ESPHome topic command: .../switch/jk-bms_{component}/command
    final String topic = '$topicPrefix/switch/jk-bms_$component/command';
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

  // --- UI ---
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
              final connected = snapshot.data?.isConnected ?? false;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.circle,
                  color: connected ? Colors.green : Colors.red,
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
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Header SoC & Voltage
              _buildMainCard(data),

              const SizedBox(height: 16),

              // 2. Control Panel (Switches)
              Text("Control", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlCard(
                    "Charge",
                    data.isCharging,
                    Icons.bolt,
                    (v) => _toggleSwitch('charging', v),
                  ),
                  _buildControlCard(
                    "Discharge",
                    data.isDischarging,
                    Icons.output,
                    (v) => _toggleSwitch('discharging', v),
                  ),
                  _buildControlCard(
                    "Balance",
                    data.isBalancing,
                    Icons.balance,
                    (v) => _toggleSwitch('balancer', v),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Cell Monitoring Grid
              Text(
                "Cell Voltages (8S)",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blueGrey.withOpacity(0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Cell ${index + 1}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "${data.cellVoltages[index]}V",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ],
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
      color: Colors.blueAccent.withOpacity(0.2),
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
                      strokeWidth: 8,
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
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  Icons.electric_meter,
                  "${data.current} A",
                  "Current",
                ),
                _buildMiniStat(Icons.flash_on, "${data.power} W", "Power"),
                _buildMiniStat(
                  Icons.thermostat,
                  "${data.tempMos}°C",
                  "MOS Temp",
                ),
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
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: value ? Colors.greenAccent : Colors.grey),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 12)),
                Switch(
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
