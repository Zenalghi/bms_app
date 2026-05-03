// Model untuk menyimpan log riwayat per-tekanan switch
class RelayTestLog {
  final int relayIndex;
  final String command;
  final int responseMs;
  RelayTestLog(this.relayIndex, this.command, this.responseMs);
}

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
    // BARU UNTUK SKRIPSI
    required List<int?> latestOnMs,
    required List<int?> latestOffMs,
    required List<RelayTestLog> relayLogs,
  }) : cellVoltages = List<double>.of(cellVoltages),
       wireRes = List<double>.of(wireRes),
       relayStates = List<bool>.of(relayStates),
       latestOnMs = List<int?>.of(latestOnMs),
       latestOffMs = List<int?>.of(latestOffMs),
       relayLogs = List<RelayTestLog>.of(relayLogs);

  final double socEKF, socCC, socKF, soh, capacityRemain;
  final double totalVoltage, current, power, tempMos, batTemp1, batTemp2;
  final List<double> cellVoltages, wireRes;
  final List<bool> relayStates;
  final bool isBalancing, isCharging, isDischarging;
  final int cellCountSetting;
  final double capacitySetting, balanceTrigV;
  final String bmsStatus;

  // BARU UNTUK SKRIPSI
  final List<int?> latestOnMs;
  final List<int?> latestOffMs;
  final List<RelayTestLog> relayLogs;

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
      cellVoltages: List.filled(8, 0.0),
      wireRes: List.filled(8, 0.0),
      isBalancing: false,
      isCharging: false,
      isDischarging: false,
      relayStates: List.filled(4, false),
      cellCountSetting: 8,
      capacitySetting: 22.0,
      balanceTrigV: 0.03,
      bmsStatus: 'offline',
      // Inisialisasi list kosong
      latestOnMs: List.filled(4, null),
      latestOffMs: List.filled(4, null),
      relayLogs: [],
    );
  }

  BmsState copyWith({
    double? socEKF,
    socCC,
    socKF,
    soh,
    totalVoltage,
    current,
    power,
    tempMos,
    batTemp1,
    batTemp2,
    capacityRemain,
    List<double>? cellVoltages,
    wireRes,
    bool? isBalancing,
    isCharging,
    isDischarging,
    List<bool>? relayStates,
    int? cellCountSetting,
    double? capacitySetting,
    balanceTrigV,
    String? bmsStatus,
    List<int?>? latestOnMs,
    List<int?>? latestOffMs,
    List<RelayTestLog>? relayLogs,
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
      latestOnMs: latestOnMs ?? this.latestOnMs,
      latestOffMs: latestOffMs ?? this.latestOffMs,
      relayLogs: relayLogs ?? this.relayLogs,
    );
  }
}
