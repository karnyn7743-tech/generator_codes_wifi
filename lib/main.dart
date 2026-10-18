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
      title: 'مولّد مفاتيح التنشيط والتجربة',
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
  static const String _secretSalt = 'EXAM_MAKER_SECURE_SALT_2026_@ALBAETHEE';

  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  String _generatedKey = '';
  bool _isTrial = false;

  void _generateKey({required bool isTrial}) {
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

    final cleanDevice = rawDevice.replaceAll('-', '').trim().toUpperCase();
    final mode = isTrial ? 'TRIAL' : 'FULL';
    final combined = '$cleanDevice:$mode:$_secretSalt';
    final hash = sha256.convert(utf8.encode(combined)).toString().toUpperCase();

    final prefix = isTrial ? 'TR' : 'FL';
    final key = '$prefix-${hash.substring(0, 4)}-${hash.substring(4, 8)}-${hash.substring(8, 12)}';

    setState(() {
      _generatedKey = key;
      _isTrial = isTrial;
    });
  }

  void _copyKey() {
    if (_generatedKey.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _generatedKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ المفتاح بنجاح'),
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

    if (_isTrial) {
      msg.writeln('تم إصدار (كود التجربة المجاني) لتطبيق صانع الاختبارات:');
      msg.writeln('رمز جهازك: ${_deviceIdController.text.trim().toUpperCase()}');
      msg.writeln('كود التجربة: $_generatedKey');
      msg.writeln('ملاحظة: يتيح لك هذا الكود تصميم وتصدير اختبار كامل لتجربة التنسيق والطباعة.');
    } else {
      msg.writeln('تم إصدار (مفتاح التنشيط الكامل الدائم) لتطبيق صانع الاختبارات:');
      msg.writeln('رمز جهازك: ${_deviceIdController.text.trim().toUpperCase()}');
      msg.writeln('مفتاح التنشيط: $_generatedKey');
      msg.writeln('مبروك! هذا المفتاح يفتح لك كامل ميزات التطبيق مدى الحياة.');
    }

    Clipboard.setData(ClipboardData(text: msg.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ رسالة واتساب جاهزة للإرسال'),
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
          'مولد مفاتيح التنشيط والتجربة | Exam Key Gen',
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
                      'إصدار ترخيص / كود تجربة',
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
                    labelText: 'اسم المعلم / المدرسة (للتوثيق)',
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

                Row(
                  children: [
                    // زر إصدار كود تجربة
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                        label: const Text(
                          'كود تجربة مجاني',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () => _generateKey(isTrial: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر إصدار ترخيص دائم
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.verified, color: Colors.white, size: 18),
                        label: const Text(
                          'مفتاح كامل دائم',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () => _generateKey(isTrial: false),
                      ),
                    ),
                  ],
                ),

                if (_generatedKey.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isTrial ? const Color(0xFF0F766E) : const Color(0xFF2563EB),
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isTrial ? 'كود التجربة المولد (اختبار واحد):' : 'مفتاح التنشيط الدائم المولد:',
                          style: TextStyle(
                            color: _isTrial ? Colors.tealAccent : Colors.lightBlueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
                            color: Colors.white,
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
                                label: const Text('نسخ الكود فقط', style: TextStyle(fontSize: 12)),
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
                                  'رسالة واتساب',
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
