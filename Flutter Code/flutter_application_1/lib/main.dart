import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  // تأكد من تهيئة الـ Firebase قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SmartPlantApp());
}

class SmartPlantApp extends StatelessWidget {
  const SmartPlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedTab = 0;

  // المراجع الخاصة بقاعدة البيانات
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Sensor values (ستتحدث تلقائياً من Firebase)
  double moisture = 0;
  double temperature = 0;
  double light = 0;

  bool autoIrrigation = false;
  bool isWatering = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // --- الربط الحقيقي مع Firebase ---
    _dbRef.child('sensor_data').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          moisture = (data['moisture'] ?? 0).toDouble();
          temperature = (data['temp'] ?? 0).toDouble();
          light = (data['light'] ?? 0).toDouble();
        });
      }
    });

    // الاستماع لحالة الري (لو الـ ESP قفل الموتور، الأبلكيشن يعرف)
    _dbRef.child('controls/pump').onValue.listen((event) {
      setState(() {
        isWatering = event.snapshot.value == true;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // إرسال أمر الري للـ Firebase
  void _toggleWatering() {
    _dbRef.child('controls').update({
      'pump': !isWatering,
    });
  }

  String get healthStatus {
    if (moisture >= 65) return 'Healthy';
    if (moisture >= 40) return 'Fair';
    return 'Needs Water';
  }

  Color get healthColor {
    if (moisture >= 65) return const Color(0xFF69F0AE);
    if (moisture >= 40) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF42E695), Color(0xFF3BB2B8)], // ألوان أقرب للفينما
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _selectedTab == 0
                    ? _buildHomeScreen()
                    : _selectedTab == 1
                        ? _buildStatisticsScreen()
                        : _buildSettingsScreen(),
              ),
              _buildNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSensorsRow(),
          const SizedBox(height: 20),
          _buildHealthCard(),
          const SizedBox(height: 14),
          _buildWaterButton(),
          const SizedBox(height: 14),
          _buildAutoIrrigationCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Plant',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text('ESP32 Connected via WiFi',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            const SizedBox(width: 8),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle)),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSensorCircle('${moisture.toStringAsFixed(0)}%', 'Moisture', moisture / 100, const Color(0xFF69F0AE), Icons.water_drop_outlined),
        _buildSensorCircle('${temperature.toStringAsFixed(1)}°C', 'Temp', (temperature - 10) / 40, const Color(0xFFFFB74D), Icons.thermostat_outlined),
        _buildSensorCircle('${light.toStringAsFixed(0)}%', 'Light', light / 100, const Color(0xFF64B5F6), Icons.wb_sunny_outlined),
      ],
    );
  }

  Widget _buildSensorCircle(String value, String label, double progress, Color arcColor, IconData icon) {
    return Column(
      children: [
        SizedBox(
          width: 88, height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(88, 88),
                painter: _ArcPainter(
                  progress: progress,
                  arcColor: arcColor,
                  bgColor: Colors.white.withOpacity(0.15),
                  strokeWidth: 6,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
      ],
    );
  }

  Widget _buildHealthCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plant Health', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(healthStatus, style: TextStyle(color: healthColor, fontSize: 22, fontWeight: FontWeight.bold)),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (ctx, _) => Opacity(opacity: _pulseAnim.value, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: healthColor, shape: BoxShape.circle))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterButton() {
    return GestureDetector(
      onTap: _toggleWatering,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isWatering
                ? [const Color(0xFF0D47A1), const Color(0xFF1565C0)]
                : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isWatering ? Icons.stop_circle : Icons.water_drop, color: Colors.white),
            const SizedBox(width: 10),
            Text(isWatering ? 'Stop Watering' : 'Water Now', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoIrrigationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Automatic Irrigation', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          Switch(
            value: autoIrrigation,
            onChanged: (v) {
              setState(() => autoIrrigation = v);
              _dbRef.child('controls').update({'auto': v});
            },
            activeColor: const Color(0xFF69F0AE),
          ),
        ],
      ),
    );
  }

  // صفحات الإحصائيات والإعدادات (مبسطة)
  Widget _buildStatisticsScreen() => const Center(child: Text("Statistics Page", style: TextStyle(color: Colors.white)));
  Widget _buildSettingsScreen() => const Center(child: Text("Settings Page", style: TextStyle(color: Colors.white)));

  Widget _buildNavBar() {
    return Container(
      color: Colors.black12,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () => setState(() => _selectedTab = 0)),
          IconButton(icon: const Icon(Icons.bar_chart, color: Colors.white), onPressed: () => setState(() => _selectedTab = 1)),
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () => setState(() => _selectedTab = 2)),
        ],
      ),
    );
  }
}

// الرسام الخاص بالدوائر (Custom Painter)
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color arcColor;
  final Color bgColor;
  final double strokeWidth;

  _ArcPainter({required this.progress, required this.arcColor, required this.bgColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bgPaint = Paint()..color = bgColor..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, bgPaint);
    final arcPaint = Paint()..color = arcColor..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0.0, 1.0), false, arcPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}