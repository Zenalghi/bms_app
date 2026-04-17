import 'dart:async';
import 'package:flutter/material.dart';

import 'models/bms_state.dart';
import 'screens/main_navigation.dart';
import 'services/mqtt_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamController<BmsState> _controller;
  late MqttService _mqttService;
  BmsState _state = BmsState.initial();

  @override
  void initState() {
    super.initState();
    _controller = StreamController<BmsState>.broadcast();
    _controller.add(_state);

    _mqttService = MqttService(
      currentState: _state,
      onStateUpdated: (newState) {
        _state = newState;
        _controller.add(_state);
      },
    );
    _mqttService.connect();
  }

  @override
  void dispose() {
    _mqttService.client.disconnect();
    _controller.close();
    super.dispose();
  }

  // === FUNGSI REFRESH BARU ===
  Future<void> _handleRefresh() async {
    await _mqttService.reconnect();
  }
  // ===========================

  void _handleRelayToggle(int index, bool value) {
    _state = _state.copyWith(
      relayStates: List<bool>.generate(
        _state.relayStates.length,
        (itemIndex) =>
            itemIndex == index ? value : _state.relayStates[itemIndex],
      ),
    );
    _mqttService.currentState = _state;
    _controller.add(_state);
    _mqttService.publishRelayCommand(index, value);
  }

  void _handleBmsSwitchToggle(String switchName, bool value) {
    if (switchName == 'charge') _state = _state.copyWith(isCharging: value);
    if (switchName == 'discharge')
      _state = _state.copyWith(isDischarging: value);
    if (switchName == 'balance') _state = _state.copyWith(isBalancing: value);

    _mqttService.currentState = _state;
    _controller.add(_state);
    _mqttService.publishBmsSwitchCommand(switchName, value);
  }

  void _handleBmsNumberSubmit(String settingName, String value) {
    _mqttService.publishBmsNumberCommand(settingName, value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMART BMS IoT',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: MainNavigation(
        stateStream: _controller.stream,
        onRelayToggle: _handleRelayToggle,
        onBmsSwitchToggle: _handleBmsSwitchToggle,
        onBmsNumberSubmit: _handleBmsNumberSubmit,
        onRefresh: _handleRefresh,
      ),
    );
  }
}
