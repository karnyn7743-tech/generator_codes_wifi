import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const KeyGenApp());
}

class KeyGenApp extends StatelessWidget {
  const KeyGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مولّد مفاتيح كنترول الاختبارات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
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
  // نفس الأملاح المستخدمة في تطبيق الكنترول بدقة
  static const String _secretSaltPermanent = "STUGRA_SCAN_SECRET_KEY_2026";
  static const String _secretSaltTrial = "STUGRA_TRIAL_KEY_2026";

  final TextEditingController _deviceIdController = TextEditingController();
  String _permanentKey = "";
  String _trialKey = "";

  // توليد المفتاح الدائم: STUG-XXXX-YYYY
  String _generatePermanentKey(String deviceId) {
    var bytes = utf8.encode(deviceId.trim() + _secretSaltPermanent);
    var digest = sha256.convert(bytes).toString().toUpperCase();
    String part1 = digest.substring(0, 4);
    String part2 = digest.substring(4, 8);
    return "STUG-$part1-$part2";
  }

  // توليد مفتاح التجربة (24 ساعة): TRIAL-XXXX-YYYY
  String _generateTrialKey(String deviceId) {
    var bytes = utf8.encode(deviceId.trim() + _secretSaltTrial);
    var digest = sha256.convert(bytes).toString().toUpperCase();
    String part1 = digest.substring(0, 4);
    String part2 = digest.substring(4, 8);
    return "TRIAL-$part1-$part2";
  }

  void _generateKeys() {
    String deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى لصق معرّف الجهاز (Device ID) أولاً!")),
      );
      return;
    }

    setState(() {
      _permanentKey = _generatePermanentKey(deviceId);
      _trialKey = _generateTrialKey(deviceId);
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم نسخ $label بنجاح")),
    );
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مولّد مفاتيح الكنترول 2026", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.vpn_key_rounded, size: 70, color: Colors.deepPurple),
            const SizedBox(height: 10),
            const Text(
              "إصدار كود التنشيط أو التجربة",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // حقل إدخال معرّف الجهاز
            TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(
                labelText: "معرّف جهاز العميل (Device ID)",
                hintText: "الصق معرّف الجهاز هنا",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone_android),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _deviceIdController.text = data!.text!.trim();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),

            // زر التوليد
            ElevatedButton.icon(
              onPressed: _generateKeys,
              icon: const Icon(Icons.lock_open, color: Colors.white),
              label: const Text(
                "توليد المفاتيح",
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 30),

            // بطاقة المفتاح الدائم
            if (_permanentKey.isNotEmpty) ...[
              _buildKeyCard(
                title: "المفتاح الدائم (مدى الحياة)",
                keyText: _permanentKey,
                cardColor: Colors.green.shade50,
                borderColor: Colors.green,
                textColor: Colors.green.shade900,
                onCopy: () => _copyToClipboard(_permanentKey, "المفتاح الدائم"),
              ),
              const SizedBox(height: 15),

              // بطاقة مفتاح التجربة (يوم واحد)
              _buildKeyCard(
                title: "مفتاح التجربة (صالح لمدة 24 ساعة)",
                keyText: _trialKey,
                cardColor: Colors.amber.shade50,
                borderColor: Colors.amber.shade800,
                textColor: Colors.amber.shade900,
                onCopy: () => _copyToClipboard(_trialKey, "مفتاح التجربة"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeyCard({
    required String title,
    required String keyText,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  keyText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: textColor),
                onPressed: onCopy,
                tooltip: "نسخ الكود",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
