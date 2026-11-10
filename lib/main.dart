import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const IoTApp());

class IoTApp extends StatelessWidget {
  const IoTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Monitoring',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorSchemeSeed: const Color(0xFF38BDF8),
      ),
      home: const DashboardPage(),
    );
  }
}

class Reading {
  final String time;
  final double temp;
  const Reading(this.time, this.temp);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ===== DATA DUMMY =====
  bool connected = true;
  double temperature = 30.5;
  int humidity = 75;
  String lastUpdate = '10:15:30';
  final String broker = 'broker.hivemq.com';
  final String topic = 'kampus/iot/kelas1/sensor';

  List<Reading> history = const [
    Reading('10:00', 28),
    Reading('10:05', 29),
    Reading('10:10', 28.5),
    Reading('10:15', 30.5),
    Reading('10:20', 31),
  ];

  Timer? _timer;
  final _rand = Random();

  static const card = Color(0xFF1E293B);
  static const accentTemp = Color(0xFFFB923C);
  static const accentHum = Color(0xFF38BDF8);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _simulate());
  }

  void _simulate() {
    if (!connected) return;
    String two(int n) => n.toString().padLeft(2, '0');
    final t = DateTime.now();
    setState(() {
      temperature = double.parse((28 + _rand.nextDouble() * 5).toStringAsFixed(1));
      humidity = 65 + _rand.nextInt(20);
      lastUpdate = '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
      final next = [...history, Reading('${two(t.hour)}:${two(t.minute)}', temperature)];
      history = next.length > 5 ? next.sublist(next.length - 5) : next;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('IoT Monitoring',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Dashboard Monitoring Sensor',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _statusPill(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _simulate(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _gaugeCard(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${_fmt(temperature)}°C',
                    progress: ((temperature - 20) / 20).clamp(0.0, 1.0),
                    color: accentTemp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _gaugeCard(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: '$humidity%',
                    progress: (humidity / 100).clamp(0.0, 1.0),
                    color: accentHum,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _mqttCard(),
            const SizedBox(height: 16),
            _historyCard(),
          ],
        ),
      ),
    );
  }

  // Status koneksi MQTT (ketuk untuk simulasi Connected/Disconnected)
  Widget _statusPill() {
    final color = connected ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    return GestureDetector(
      onTap: () => setState(() => connected = !connected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 9, color: color),
            const SizedBox(width: 6),
            Text(connected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // Kartu nilai sensor dengan gauge melingkar
  Widget _gaugeCard({
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
      BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            width: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CustomPaint(painter: GaugePainter(progress, color)),
                ),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Sensor DHT11',
              style: TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 10),
          Text(k, style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _mqttCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
      BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MQTT Connection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          _infoTile(Icons.dns_outlined, 'Broker', broker),
          const Divider(height: 1, color: Colors.white12),
          _infoTile(Icons.tag, 'Topic', topic),
          const Divider(height: 1, color: Colors.white12),
          _infoTile(Icons.schedule, 'Last Update', lastUpdate),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
      BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monitoring History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Dummy Data', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Temperature (°C) · data simulasi untuk desain dashboard',
              style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: BarChartPainter(history)),
          ),
          const SizedBox(height: 12),
          ...history.reversed.map(
                (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.time,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${_fmt(r.temp)}°C',
                      style: const TextStyle(color: accentTemp)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gauge melingkar sederhana.
class GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  GaugePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final bg = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    const start = 0.75 * pi;
    const sweep = 1.5 * pi;
    canvas.drawArc(rect, start, sweep, false, bg);
    canvas.drawArc(rect, start, sweep * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant GaugePainter old) =>
      old.progress != progress || old.color != color;
}

/// Grafik batang sederhana tanpa package tambahan.
class BarChartPainter extends CustomPainter {
  final List<Reading> data;
  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const labelH = 20.0;
    final chartH = size.height - labelH;
    final maxV = data.map((e) => e.temp).reduce(max) + 2;
    final minV = data.map((e) => e.temp).reduce(min) - 4;
    final slot = size.width / data.length;
    final barW = slot * 0.5;

    final grid = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartH * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var i = 0; i < data.length; i++) {
      final h = chartH * (data[i].temp - minV) / (maxV - minV);
      final x = slot * i + (slot - barW) / 2;
      final isLast = i == data.length - 1;
      final paint = Paint()
        ..color = isLast ? const Color(0xFFFB923C) : const Color(0xFF475569);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, chartH - h, barW, h), const Radius.circular(6)),
        paint,
      );
      final tp = TextPainter(
        text: TextSpan(
            text: data[i].time,
            style: const TextStyle(fontSize: 10, color: Colors.white54)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(slot * i + (slot - tp.width) / 2, chartH + 5));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter old) => old.data != data;
}
