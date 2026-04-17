import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/bms_state.dart';

class MqttService {
  final String broker = 'broker.mqtt.cool';
  final int port = 1883;
  late MqttServerClient client;
  final void Function(BmsState) onStateUpdated;
  BmsState currentState;

  MqttService({required this.currentState, required this.onStateUpdated}) {
    client = MqttServerClient(
      broker,
      'flutter_bms_${DateTime.now().millisecondsSinceEpoch}',
    );
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 60;
  }

  Future<void> connect() async {
    try {
      await client.connect();
      _subscribeToTopics();
    } catch (e) {
      client.disconnect();
    }
  }

  void _subscribeToTopics() {
    client.subscribe('bms_panel/260216/data/main', MqttQos.atMostOnce);
    client.subscribe('bms_panel/260216/data/soc_bawaan', MqttQos.atMostOnce);
    client.subscribe('bms_panel/260216/state/switches', MqttQos.atMostOnce);
    client.subscribe('bms_panel/260216/state/settings', MqttQos.atMostOnce);
    client.subscribe('bms_panel/260216/status', MqttQos.atMostOnce); // BARU

    client.updates!.listen((c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      _handleMessage(c[0].topic, payload);
    });
  }

  void _handleMessage(String topic, String payload) {
    try {
      // Handle status LWT (Last Will and Testament) biasa berupa teks murni, bukan JSON
      if (topic.endsWith('/status')) {
        currentState = currentState.copyWith(bmsStatus: payload);
        onStateUpdated(currentState);
        return;
      }

      final data = jsonDecode(payload);

      if (topic.contains('data/main')) {
        currentState = currentState.copyWith(
          totalVoltage: (data['voltage'] ?? 0).toDouble(),
          current: (data['current'] ?? 0).toDouble(),
          power: (data['power'] ?? 0).toDouble(),
          tempMos: (data['mos_temp'] ?? 0).toDouble(),
          batTemp1: (data['bat_temp1'] ?? 0).toDouble(),
          batTemp2: (data['bat_temp2'] ?? 0).toDouble(),
          cellVoltages: List<double>.from(
            (data['cells_v'] ?? []).map((x) => (x as num).toDouble()),
          ),
          wireRes: List<double>.from(
            (data['wire_res'] ?? []).map((x) => (x as num).toDouble()),
          ),
        );
      } else if (topic.contains('data/soc_bawaan')) {
        currentState = currentState.copyWith(
          socCC: (data['soc_jk'] ?? 0).toDouble(),
          capacityRemain: (data['capacity_remain'] ?? 0).toDouble(),
        );
      } else if (topic.contains('state/switches')) {
        currentState = currentState.copyWith(
          isCharging: data['charge_switch'] == 'ON',
          isDischarging: data['discharge_switch'] == 'ON',
          isBalancing: data['balance_switch'] == 'ON',
        );
      } else if (topic.contains('state/settings')) {
        currentState = currentState.copyWith(
          cellCountSetting: data['cell_count_setting'] ?? 8,
          capacitySetting: (data['capacity_setting'] ?? 0).toDouble(),
          balanceTrigV: (data['balance_trig_v'] ?? 0).toDouble(),
        );
      }
      onStateUpdated(currentState);
    } catch (e) {
      print('Error parsing dari $topic: $e');
    }
  }

  // Kontrol Relay Eksternal
  void publishRelayCommand(int index, bool uiIsOn) {
    final command = uiIsOn ? 'ON' : 'OFF';
    final List<String> relayTopics = [
      'bms_panel/260216/switch/relay_1/command',
      'bms_panel/260216/switch/relay_2/command',
      'bms_panel/260216/switch/relay_3/command',
      'bms_panel/260216/switch/relay_4/command',
    ];
    _publishString(relayTopics[index], command);
  }

  // Kontrol Switch Internal BMS (Charge/Discharge/Balance)
  void publishBmsSwitchCommand(String switchName, bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    final topic = 'bms_panel/260216/switch/${switchName}_switch/command';
    _publishString(topic, command);
  }

  // Kontrol Setting Angka BMS (Cell Count/Capacity/Balance Trig)
  void publishBmsNumberCommand(String settingName, String value) {
    final topic = 'bms_panel/260216/number/$settingName/command';
    _publishString(topic, value);
  }

  void _publishString(String topic, String payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print('Command sent -> Topic: $topic | Payload: $payload');
  }
}
