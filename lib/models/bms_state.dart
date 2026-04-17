class BmsState {
  BmsState({
    required this.socEKF,
    required this.socCC,
    required this.socKF,
    required this.soh,
    required this.totalVoltage,
    required this.current,
    required this.power,
    required this.tempMos,
    required this.batTemp1,
    required this.batTemp2,
    required this.capacityRemain,
    required List<double> cellVoltages,
    required List<double> wireRes,
    required this.isBalancing,
    required this.isCharging,
    required this.isDischarging,
    required List<bool> relayStates,
    // Settings
    required this.cellCountSetting,
    required this.capacitySetting,
    required this.balanceTrigV,
    // Status
    required this.bmsStatus,
  }) : cellVoltages = List<double>.of(cellVoltages),
       wireRes = List<double>.of(wireRes),
       relayStates = List<bool>.of(relayStates);

  // Core Metrics
  final double socEKF;
  final double socCC;
  final double socKF;
  final double soh;
  final double capacityRemain;

  // Electrical & Thermal
  final double totalVoltage;
  final double current;
  final double power;
  final double tempMos;
  final double batTemp1;
  final double batTemp2;

  // Arrays
  final List<double> cellVoltages;
  final List<double> wireRes;
  final List<bool> relayStates;

  // Internal Switches
  final bool isBalancing;
  final bool isCharging;
  final bool isDischarging;

  // Settings
  final int cellCountSetting;
  final double capacitySetting;
  final double balanceTrigV;

  // Connectivity
  final String bmsStatus;

  factory BmsState.initial() {
    return BmsState(
      socEKF: 0.0,
      socCC: 0.0,
      socKF: 0.0,
      soh: 100.0,
      totalVoltage: 0.0,
      current: 0.0,
      power: 0.0,
      tempMos: 0.0,
      batTemp1: 0.0,
      batTemp2: 0.0,
      capacityRemain: 0.0,
      cellVoltages: List.filled(8, 0.0), // Konfigurasi default 8S
      wireRes: List.filled(8, 0.0),
      isBalancing: false,
      isCharging: false,
      isDischarging: false,
      relayStates: List.filled(4, false), // 4 Channel Relay
      cellCountSetting: 8, // Default Cell Count: 8
      capacitySetting: 22.0, // Default Capacity: 22 Ah
      balanceTrigV: 0.03, // Default Balance Trigger: 0.03 V
      // ==================================
      bmsStatus: 'offline',
    );
  }

  BmsState copyWith({
    double? socEKF,
    double? socCC,
    double? socKF,
    double? soh,
    double? totalVoltage,
    double? current,
    double? power,
    double? tempMos,
    double? batTemp1,
    double? batTemp2,
    double? capacityRemain,
    List<double>? cellVoltages,
    List<double>? wireRes,
    bool? isBalancing,
    bool? isCharging,
    bool? isDischarging,
    List<bool>? relayStates,
    int? cellCountSetting,
    double? capacitySetting,
    double? balanceTrigV,
    String? bmsStatus,
  }) {
    return BmsState(
      socEKF: socEKF ?? this.socEKF,
      socCC: socCC ?? this.socCC,
      socKF: socKF ?? this.socKF,
      soh: soh ?? this.soh,
      totalVoltage: totalVoltage ?? this.totalVoltage,
      current: current ?? this.current,
      power: power ?? this.power,
      tempMos: tempMos ?? this.tempMos,
      batTemp1: batTemp1 ?? this.batTemp1,
      batTemp2: batTemp2 ?? this.batTemp2,
      capacityRemain: capacityRemain ?? this.capacityRemain,
      cellVoltages: cellVoltages ?? this.cellVoltages,
      wireRes: wireRes ?? this.wireRes,
      isBalancing: isBalancing ?? this.isBalancing,
      isCharging: isCharging ?? this.isCharging,
      isDischarging: isDischarging ?? this.isDischarging,
      relayStates: relayStates ?? this.relayStates,
      cellCountSetting: cellCountSetting ?? this.cellCountSetting,
      capacitySetting: capacitySetting ?? this.capacitySetting,
      balanceTrigV: balanceTrigV ?? this.balanceTrigV,
      bmsStatus: bmsStatus ?? this.bmsStatus,
    );
  }
}
