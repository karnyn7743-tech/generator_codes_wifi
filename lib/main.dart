import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const ExamKeyGenApp());
}

class ExamKeyGenApp extends StatelessWidget {
  const ExamKeyGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مفاتيح تنشيط المحرر البسيط للإختبارات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'YE'),
      supportedLocales: const [Locale('ar', 'YE'), Locale('ar', '')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const KeyGeneratorScreen(),
    );
  }
}

class KeyGeneratorScreen extends StatefulWidget {
  const KeyGeneratorScreen({super.key});

  @override
  State<KeyGeneratorScreen> createState() => _KeyGeneratorScreenState();
}

class _KeyGeneratorScreenState extends State<KeyGeneratorScreen> {
  // المفتاح السري المطابق تماماً لما في التطبيق الرئيسي
  static const String _secretSalt = 'EXAM_MAKER_SECURE_SALT_2026_@ALBAETHEE';

  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  String _generatedKey = '';

  void _generateKey() {
    final rawDevice = _deviceIdController.text.trim();
    if (rawDevice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رمز جهاز المعلم أولاً'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // تنظيف رمز الجهاز وإزالة الفواصل
    final cleanDevice = rawDevice.replaceAll('-', '').trim().toUpperCase();
    final combined = '$cleanDevice:$_secretSalt';
    final hash = sha256.convert(utf8.encode(combined)).toString().toUpperCase();

    // تشكيل المفتاح المكون من 16 خانة (4 مجموعات)
    final key = '${hash.substring(0, 4)}-${hash.substring(4, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}';

    setState(() {
      _generatedKey = key;
    });
  }

  void _copyKey() {
    if (_generatedKey.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _generatedKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ مفتاح التنشيط إلى الحافظة بنجاح'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyFullShareMessage() {
    if (_generatedKey.isEmpty) return;
    final teacher = _teacherNameController.text.trim();
    final msg = StringBuffer();
    if (teacher.isNotEmpty) {
      msg.writeln('مرحباً بك أستاذ/ $teacher');
    }
    msg.writeln('مفتاح تنشيط تطبيق صانع الاختبارات لجهازك:');
    msg.writeln('رمز الجهاز: ${_deviceIdController.text.trim().toUpperCase()}');
    msg.writeln('مفتاح التنشيط: $_generatedKey');
    msg.writeln('ملاحظة: هذا المفتاح مخصص لجهازك فقط ولا يعمل على جهاز آخر.');

    Clipboard.setData(ClipboardData(text: msg.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ رسالة الترخيص المكتملة لإرسالها للمعلم'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مولد مفاتيح التنشيط | Exam Key Gen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueGrey.shade800),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.vpn_key_rounded, color: Color(0xFF38BDF8), size: 28),
                    SizedBox(width: 8),
                    Text(
                      'إصدار ترخيص جديد للمعلم',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.blueGrey),

                TextField(
                  controller: _teacherNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'اسم المعلم / المدرسة (اختياري للتوثيق)',
                    labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF38BDF8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _deviceIdController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'رمز الجهاز المرسل من المعلم (Device ID)',
                    labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    hintText: 'XXXX-XXXX-XXXX',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: const Icon(Icons.phonelink_setup, color: Color(0xFF38BDF8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  label: const Text(
                    'توليد مفتاح التنشيط',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _generateKey,
                ),

                if (_generatedKey.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF059669), width: 1.2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'مفتاح التنشيط المولد:',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          _generatedKey,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            fontFamily: 'monospace',
                            color: Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.blueGrey),
                                ),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('نسخ المفتاح فقط', style: TextStyle(fontSize: 12)),
                                onPressed: _copyKey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                ),
                                icon: const Icon(Icons.share, color: Colors.white, size: 16),
                                label: const Text(
                                  'نسخ رسالة واتساب',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                onPressed: _copyFullShareMessage,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
