class FirebaseBmsData {
  final double avgCellV, batTemp1, batTemp2, current, deltaV;
  final double maxCellV, minCellV, mosTemp, power, roomHum;
  final double roomTemp, socCC, socEKF, voltage;

  FirebaseBmsData({
    required this.avgCellV, required this.batTemp1, required this.batTemp2,
    required this.current, required this.deltaV, required this.maxCellV,
    required this.minCellV, required this.mosTemp, required this.power,
    required this.roomHum, required this.roomTemp, required this.socCC,
    required this.socEKF, required this.voltage,
  });

  factory FirebaseBmsData.initial() {
    return FirebaseBmsData(
      avgCellV: 0, batTemp1: 0, batTemp2: 0, current: 0, deltaV: 0,
      maxCellV: 0, minCellV: 0, mosTemp: 0, power: 0, roomHum: 0,
      roomTemp: 0, socCC: 0, socEKF: 0, voltage: 0,
    );
  }

  factory FirebaseBmsData.fromMap(Map<dynamic, dynamic> map) {
    return FirebaseBmsData(
      avgCellV: (map['avg_cell_v'] ?? 0).toDouble(),
      batTemp1: (map['bat_temp1'] ?? 0).toDouble(),
      batTemp2: (map['bat_temp2'] ?? 0).toDouble(),
      current: (map['current'] ?? 0).toDouble(),
      deltaV: (map['delta_v'] ?? 0).toDouble(),
      maxCellV: (map['max_cell_v'] ?? 0).toDouble(),
      minCellV: (map['min_cell_v'] ?? 0).toDouble(),
      mosTemp: (map['mos_temp'] ?? 0).toDouble(),
      power: (map['power'] ?? 0).toDouble(),
      roomHum: (map['room_hum'] ?? 0).toDouble(),
      roomTemp: (map['room_temp'] ?? 0).toDouble(),
      socCC: (map['soc_cc'] ?? 0).toDouble(),
      socEKF: (map['soc_ekf'] ?? 0).toDouble(),
      voltage: (map['voltage'] ?? 0).toDouble(),
    );
  }
}