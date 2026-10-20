import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as enc;

void main() {
  runApp(const KeyGeneratorApp());
}

class KeyGeneratorApp extends StatelessWidget {
  const KeyGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مولّد مفاتيح نظام الأرشفة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const GeneratorScreen(),
    );
  }
}

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  // نفس المفتاح السري الموجود في تطبيق الأرشفة تماماً
  static const String _secretKeyString = "MySecretKeyArchivesApp2026!#Safe";

  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(text: "15");

  String _licenseType = "TRIAL"; // 'TRIAL' أو 'LIFETIME'
  String _generatedKey = "";

  void _generateKey() {
    final deviceId = _deviceIdController.text.trim().toUpperCase();

    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال معرّف الجهاز الخاص بالعميل أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final keyBytes = enc.Key.fromUtf8(_secretKeyString);
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(enc.AES(keyBytes, mode: enc.AESMode.cbc));

      String payload = "";

      if (_licenseType == "LIFETIME") {
        // مفتاح مدى الحياة
        payload = "$deviceId|LIFETIME|NONE";
      } else {
        // مفتاح تجريبي
        final int days = int.tryParse(_daysController.text.trim()) ?? 15;
        final DateTime expiry = DateTime.now().add(Duration(days: days));
        final String expiryStr =
            "${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}";
        payload = "$deviceId|TRIAL|$expiryStr";
      }

      final encrypted = encrypter.encrypt(payload, iv: iv);

      setState(() {
        _generatedKey = encrypted.base64;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التوليد: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard() {
    if (_generatedKey.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedKey));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ مفتاح التنشيط بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مولّد مفاتيح التنشيط'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                elevation: 0,
                color: Color(0xFFE8F5E9),
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key_rounded, color: Colors.teal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'أداة الإدارة الخاصة بتوليد تراخيص تطبيق الأرشفة والسكرتارية',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // حقل كود الجهاز
              TextField(
                controller: _deviceIdController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                decoration: InputDecoration(
                  labelText: 'معرّف جهاز العميل (Device ID)',
                  hintText: 'مثال: A1B2C3D4E5F6',
                  prefixIcon: const Icon(Icons.phone_android),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _deviceIdController.clear(),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // اختيار نوع المفتاح
              const Text(
                'نوع التفعيل:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('تجريبي'),
                      value: 'TRIAL',
                      groupValue: _licenseType,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() => _licenseType = val!);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('مدى الحياة'),
                      value: 'LIFETIME',
                      groupValue: _licenseType,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() => _licenseType = val!);
                      },
                    ),
                  ),
                ],
              ),

              // حقل عدد الأيام في حالة التجريبي
              if (_licenseType == 'TRIAL') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'مدة الصلاحية بالأيام',
                    suffixText: 'يوم',
                    prefixIcon: Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // زر التوليد
              ElevatedButton.icon(
                onPressed: _generateKey,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('توليد مفتاح التنشيط', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // عرض النتيجة
              if (_generatedKey.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'المفتاح الناتج للعميل:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: SelectableText(
                    _generatedKey,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ المفتاح للإرسال عبر واتساب'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
