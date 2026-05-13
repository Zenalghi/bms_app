import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/firebase_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref('bms_realtime');

    return StreamBuilder<DatabaseEvent>(
      stream: databaseRef.onValue,
      builder: (context, snapshot) {
        FirebaseBmsData data = FirebaseBmsData.initial();

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final rawData = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
          data = FirebaseBmsData.fromMap(rawData);
        }

        final items = [
          _DataPoint(
            "SOC (EKF)",
            "${data.socEKF.toStringAsFixed(1)}%",
            const Color(0xFF00BCD4),
          ),
          _DataPoint(
            "SOC (CC)",
            "${data.socCC.toStringAsFixed(1)}%",
            Colors.orangeAccent,
          ),
          _DataPoint(
            "Voltage",
            "${data.voltage.toStringAsFixed(2)}V",
            Colors.greenAccent,
          ),
          _DataPoint(
            "Current",
            "${data.current.toStringAsFixed(2)}A",
            Colors.yellowAccent,
          ),
          _DataPoint(
            "Power",
            "${data.power.toStringAsFixed(1)}W",
            Colors.purpleAccent,
          ),
          _DataPoint(
            "Avg Cell",
            "${data.avgCellV.toStringAsFixed(3)}V",
            Colors.blueAccent,
          ),
          _DataPoint(
            "Delta V",
            "${data.deltaV.toStringAsFixed(3)}V",
            Colors.redAccent,
          ),
          _DataPoint(
            "Max Cell",
            "${data.maxCellV.toStringAsFixed(3)}V",
            Colors.green,
          ),
          _DataPoint(
            "Min Cell",
            "${data.minCellV.toStringAsFixed(3)}V",
            Colors.red,
          ),
          _DataPoint("MOS Temp", "${data.mosTemp}°C", Colors.deepOrangeAccent),
          _DataPoint("Bat Temp 1", "${data.batTemp1}°C", Colors.tealAccent),
          _DataPoint("Bat Temp 2", "${data.batTemp2}°C", Colors.tealAccent),
          _DataPoint(
            "Room Temp",
            "${data.roomTemp.toStringAsFixed(1)}°C",
            Colors.pinkAccent,
          ),
          _DataPoint(
            "Humidity",
            "${data.roomHum.toStringAsFixed(0)}%",
            Colors.lightBlueAccent,
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Cloud',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'BMS Data from Firebase',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildCard(items[index]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(_DataPoint item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: item.color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centered vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Centered horizontally
        children: [
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: item.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataPoint {
  final String title;
  final String value;
  final Color color;
  _DataPoint(this.title, this.value, this.color);
}
