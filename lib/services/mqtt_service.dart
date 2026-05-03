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
      print('Menghubungkan ke MQTT Broker...');
      await client.connect();
      print('MQTT Terhubung!');
      _subscribeToTopics();
    } catch (e) {
      print('Gagal terhubung: $e');
      client.disconnect();
    }
  }

  // === FUNGSI RECONNECT BARU ===
  Future<void> reconnect() async {
    print('Mencoba menyambungkan ulang MQTT...');
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect();
    }

    // Ubah status ke offline sementara agar UI tahu sedang proses reconnect
    currentState = currentState.copyWith(bmsStatus: 'offline');
    onStateUpdated(currentState);

    await connect();
  }

  // =============================
  final Map<int, Map<String, dynamic>> _pendingRelayCommands = {};
  void _subscribeToTopics() {
    client.subscribe('bms_panel/2602165/data/main', MqttQos.atMostOnce);
    client.subscribe('bms_panel/2602165/data/soc_bawaan', MqttQos.atMostOnce);
    client.subscribe('bms_panel/2602165/state/switches', MqttQos.atMostOnce);
    client.subscribe('bms_panel/2602165/state/settings', MqttQos.atMostOnce);
    client.subscribe('bms_panel/2602165/status', MqttQos.atMostOnce);

    // Topik baru khusus untuk konfirmasi balik status Relay dari ESP32
    client.subscribe('bms_panel/2602165/state/relays', MqttQos.atMostOnce);

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
      if (topic.endsWith('/status')) {
        currentState = currentState.copyWith(bmsStatus: payload);
        onStateUpdated(currentState);
        return;
      }

      final data = jsonDecode(payload);

      // LOGIKA STOPWATCH RESPON TIME RELAY
      if (topic.contains('state/relays')) {
        List<int?> newOnMs = List.from(currentState.latestOnMs);
        List<int?> newOffMs = List.from(currentState.latestOffMs);
        List<RelayTestLog> newLogs = List.from(currentState.relayLogs);

        bool isUpdated = false;

        // Cek 4 relay
        for (int i = 0; i < 4; i++) {
          String key = 'relay_${i + 1}'; // contoh: relay_1
          if (data.containsKey(key)) {
            String actualState = data[key]; // "ON" atau "OFF"

            // Cek apakah relay ini sedang kita tunggu responsnya
            if (_pendingRelayCommands.containsKey(i)) {
              if (_pendingRelayCommands[i]!['expectedState'] == actualState) {
                // Berhasil! Hitung selisih waktu
                DateTime startTime = _pendingRelayCommands[i]!['startTime'];
                int responseTimeMs = DateTime.now()
                    .difference(startTime)
                    .inMilliseconds;

                // Hapus dari antrean
                _pendingRelayCommands.remove(i);

                // Update UI log
                if (actualState == 'ON')
                  newOnMs[i] = responseTimeMs;
                else
                  newOffMs[i] = responseTimeMs;

                // Masukkan ke database untuk dieksport CSV
                newLogs.add(RelayTestLog(i, actualState, responseTimeMs));
                isUpdated = true;
              }
            }
          }
        }

        if (isUpdated) {
          currentState = currentState.copyWith(
            latestOnMs: newOnMs,
            latestOffMs: newOffMs,
            relayLogs: newLogs,
          );
        }
      }
      // Sisa parsing data lainnya (main, soc_bawaan, switches) tetap di sini...
      else if (topic.contains('data/main')) {
        // ... kode bawaanmu sebelumnya ...
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
      print('Error parsing JSON dari $topic: $e');
    }
  }

  // Kontrol Relay Eksternal
  void publishRelayCommand(int index, bool uiIsOn) {
    final command = uiIsOn ? 'ON' : 'OFF';
    final List<String> relayTopics = [
      'bms_panel/2602165/switch/relay_1/command',
      'bms_panel/2602165/switch/relay_2/command',
      'bms_panel/2602165/switch/relay_3/command',
      'bms_panel/2602165/switch/relay_4/command',
    ];

    // MULAI STOPWATCH
    _pendingRelayCommands[index] = {
      'startTime': DateTime.now(),
      'expectedState': command,
    };

    _publishString(relayTopics[index], command);
  }

  // Kontrol Switch Internal BMS (Charge/Discharge/Balance)
  void publishBmsSwitchCommand(String switchName, bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    final topic = 'bms_panel/26021655/switch/${switchName}_switch/command';
    _publishString(topic, command);
  }

  // Kontrol Setting Angka BMS (Cell Count/Capacity/Balance Trig)
  void publishBmsNumberCommand(String settingName, String value) {
    final topic = 'bms_panel/26021655/number/$settingName/command';
    _publishString(topic, value);
  }

  void _publishString(String topic, String payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print('Command sent -> Topic: $topic | Payload: $payload');
  }
}
