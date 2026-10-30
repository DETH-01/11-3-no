import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const studentInfo = '(016840641011-3 ณพกร)';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ล็อกให้เป็นแนวตั้ง (มีผลบนมือถือ/โปรแกรมจำลอง)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบคำนวณรายได้และประเมินค่าใช้จ่าย',
      debugShowCheckedModeBanner: false,
      // บนเว็บ: บีบเนื้อหาเป็นคอลัมน์แนวตั้งกว้างไม่เกิน 420
      builder: (context, child) => ColoredBox(
        color: const Color(0xFF263238),
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SizedBox(
              width: constraints.maxWidth < 420 ? constraints.maxWidth : 420,
              height: constraints.maxHeight,
              child: child,
            ),
          ),
        ),
      ),
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00796B),
        useMaterial3: true,
      ),
      home: const Screen1(),
    );
  }
}

/// แปลงข้อความเป็นตัวเลข คืน null ถ้าว่าง/ไม่ใช่ตัวเลข
double? parseNum(String text) {
  final v = double.tryParse(text.trim());
  if (v == null || !v.isFinite) return null;
  return v;
}

// ======================= Screen 1 =======================
class Screen1 extends StatefulWidget {
  const Screen1({super.key});

  @override
  State<Screen1> createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  final _salaryCtrl = TextEditingController();
  final _salesCtrl = TextEditingController();
  double? _net;

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _salesCtrl.dispose();
    super.dispose();
  }

  /// กล่องแจ้งเตือนข้อผิดพลาด (สีแดง)
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade700,
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิดหน้าต่าง',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// กล่องสรุปรายได้ประจำเดือน (มีโลโก้ดาว)
  void _showSummary({
    required Color color,
    required String tier,
    required double salary,
    required double rate,
    required double commission,
    required double bonus,
    required double extra,
    required double net,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวกล่อง: โลโก้ + ชื่อ
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'สรุปรายได้ประจำเดือน',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('ระดับผลงาน: $tier'),
              const SizedBox(height: 4),
              Text('• ฐานเงินเดือน: ${salary.toStringAsFixed(2)} บาท'),
              Text(
                  '• ค่าคอมมิชชัน (${(rate * 100).toInt()}%): ${commission.toStringAsFixed(2)} บาท'),
              Text('• โบนัสพิเศษ: ${bonus.toStringAsFixed(2)} บาท'),
              Text('• เงินพิเศษเพิ่มเติม: ${extra.toStringAsFixed(2)} บาท'),
              const Text('------------------------------------'),
              Text('รายได้รวมสุทธิ: ${net.toStringAsFixed(2)} บาท'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('ปิดหน้าต่าง',
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _calculate() {
    final salary = parseNum(_salaryCtrl.text);
    final sales = parseNum(_salesCtrl.text);

    // ข้อมูลไม่ถูกต้อง: ว่าง / ไม่ใช่ตัวเลข / ติดลบ
    if (salary == null || sales == null || salary < 0 || sales < 0) {
      _net = null;
      _showError('ข้อผิดพลาด: กรุณากรอกตัวเลขที่ถูกต้อง (ห้ามว่าง ห้ามติดลบ)');
      return;
    }

    final rate = salary < 20000 ? 0.05 : (salary <= 50000 ? 0.08 : 0.12);
    final commission = sales * rate;
    final bonus = sales >= 200000 ? 3000.0 : 0.0;
    // เงินพิเศษเพิ่มเติม (ตาม TC-03): ฐานเงินเดือน > 50,000 ได้ +5,000
    final extra = salary > 50000 ? 5000.0 : 0.0;
    final net = salary + commission + bonus + extra;
    _net = net;

    final color = net < 30000
        ? Colors.orange.shade800
        : (net <= 70000 ? Colors.blue.shade800 : Colors.green.shade800);

    final tier = salary < 20000
        ? 'Bronze Tier (เริ่มต้น)'
        : (salary <= 50000 ? 'Silver Tier (ระดับกลาง)' : 'Gold Tier (ระดับสูง)');

    _showSummary(
      color: color,
      tier: tier,
      salary: salary,
      rate: rate,
      commission: commission,
      bonus: bonus,
      extra: extra,
      net: net,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF4FF),
      appBar: AppBar(
        title: Text(
          'Screen 1: คำนวณรายได้ $studentInfo',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'หน้าถัดไป',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Screen2(netIncome: _net)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet,
                size: 72, color: Color(0xFF3949AB)),
            const SizedBox(height: 12),
            const Text(
              'คำนวณเงินเดือน + ค่าคอมมิชชั่น',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _salaryCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'ฐานเงินเดือน (บาท)',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _salesCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'ยอดขายรวม (บาท)',
                prefixIcon: Icon(Icons.shopping_cart),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text('คำนวณ'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF003366)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Screen 2 =======================
class Screen2 extends StatefulWidget {
  final double? netIncome;
  const Screen2({super.key, this.netIncome});

  @override
  State<Screen2> createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  late final TextEditingController _incomeCtrl;
  final _expenseCtrl = TextEditingController();
  String? _message;
  Color _color = Colors.green;

  @override
  void initState() {
    super.initState();
    // รับรายได้สุทธิจาก Screen 1
    _incomeCtrl = TextEditingController(
        text: widget.netIncome == null ? '' : widget.netIncome.toString());
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _expenseCtrl.dispose();
    super.dispose();
  }

  void _assess() {
    final income = parseNum(_incomeCtrl.text);
    final expense = parseNum(_expenseCtrl.text);

    if (income == null || expense == null || income <= 0 || expense < 0) {
      _setResult(Colors.red.shade700,
          'ข้อผิดพลาด: กรอกตัวเลขที่ถูกต้อง (รายได้ต้องมากกว่า 0 และห้ามติดลบ)');
      return;
    }

    final pct = expense / income * 100;
    final p = pct.toStringAsFixed(1);

    // แจ้งเตือน 3 แบบ (TC-05)
    if (pct <= 50) {
      _setResult(Colors.green.shade800,
          'เยี่ยมมาก! ค่าใช้จ่าย $p% คุณมีเงินเหลือออมเกิน 50%');
    } else if (pct <= 100) {
      _setResult(Colors.deepOrange.shade700,
          'ควรระวัง ค่าใช้จ่าย $p% เหลือเงินออมน้อย');
    } else {
      _setResult(Colors.red.shade700,
          'ใช้เกินรายได้! ค่าใช้จ่าย $p% ของรายได้');
    }
  }

  void _setResult(Color color, String msg) {
    setState(() {
      _color = color;
      _message = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFCF4),
      appBar: AppBar(
        title: const Text(
          'Screen 2: ประเมินค่าใช้จ่าย',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFF2A857A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.pie_chart_outline,
                size: 64, color: Color(0xFF00A58E)),
            const SizedBox(height: 8),
            const Text('ประเมินสัดส่วนค่าใช้จ่ายประจำเดือน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _incomeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'รายได้รวมสุทธิ (บาท)',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expenseCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'ค่าใช้จ่ายคงที่ประจำเดือน (บาท)',
                prefixIcon: Icon(Icons.shopping_cart),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _assess,
                icon: const Icon(Icons.pie_chart),
                label: const Text('ประเมินสัดส่วน'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B)),
              ),
            ),
            const SizedBox(height: 24),
            if (_message != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}