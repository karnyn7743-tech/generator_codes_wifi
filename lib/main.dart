import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'keygen_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MasterKeygenApp());
}

class MasterKeygenApp extends StatelessWidget {
  const MasterKeygenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مولّد مفاتيح التنشيط',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const KeygenHomeScreen(),
    );
  }
}

class KeygenHomeScreen extends StatefulWidget {
  const KeygenHomeScreen({super.key});

  @override
  State<KeygenHomeScreen> createState() => _KeygenHomeScreenState();
}

class _KeygenHomeScreenState extends State<KeygenHomeScreen> {
  final _idController = TextEditingController();
  final _clientNameController = TextEditingController();

  String? _generatedKey;
  String? _errorMessage;
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('keygen_history_log');
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        setState(() {
          _history = list.map((e) => Map<String, String>.from(e as Map)).toList();
        });
      } catch (_) {}
    }
  }

  Future<void> _saveToHistory(String name, String id, String key) async {
    final prefs = await SharedPreferences.getInstance();
    final item = {
      'name': name.isEmpty ? 'مشرف بدون اسم' : name,
      'id': id,
      'key': key,
      'date': DateTime.now().toString().split('.').first,
    };
    final updated = [item, ..._history];
    await prefs.setString('keygen_history_log', jsonEncode(updated));
    setState(() => _history = updated);
  }

  void _generateActivationKey() {
    setState(() {
      _errorMessage = null;
      _generatedKey = null;
    });

    final rawInput = _idController.text;
    final normalizedId = KeygenCore.normalizeFingerprint(rawInput);

    if (normalizedId == null) {
      setState(() {
        _errorMessage = 'صيغة المعرف غير صحيحة! يجب أن تكون مثل: NET-A1B2-C3D4';
      });
      return;
    }

    final key = KeygenCore.generateKey(normalizedId);

    setState(() {
      _idController.text = normalizedId;
      _generatedKey = key;
    });

    _saveToHistory(_clientNameController.text.trim(), normalizedId, key);
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مولّد مفاتيح التنشيط المعتمد', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key, color: Colors.deepPurple, size: 28),
                        SizedBox(width: 8),
                        Text('توليد رخصة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المشرف / الشبكة (اختياري)',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _idController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'معرف الجهاز المطلوب تنشيطه',
                        hintText: 'NET-XXXX-XXXX',
                        prefixIcon: const Icon(Icons.fingerprint),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste),
                          tooltip: 'لصق من الحافظة',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _idController.text = data!.text!.trim();
                            }
                          },
                        ),
                        border: const OutlineInputBorder(),
                        errorText: _errorMessage,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _generateActivationKey,
                      icon: const Icon(Icons.generating_tokens),
                      label: const Text('توليد مفتاح التنشيط', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            if (_generatedKey != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.deepPurple.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'مفتاح التنشيط الصادر:',
                        style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        _generatedKey!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.copy),
                        label: const Text('نسخ المفتاح وإرساله للمشرف'),
                        onPressed: () => _copyToClipboard(_generatedKey!, 'تم نسخ مفتاح التنشيط بنجاح!'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سجل المفاتيح الصادرة (${_history.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_history.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('مسح السجل', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('keygen_history_log');
                      setState(() => _history = []);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _history.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('لا توجد مفاتيح صادرة مسجلة بعد', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = _history[idx];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.key, size: 20),
                        ),
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'المعرف: ${item['id']}\nالمفتاح: ${item['key']}\nالتاريخ: ${item['date']}',
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, color: Colors.deepPurple, size: 20),
                          tooltip: 'نسخ المفتاح',
                          onPressed: () => _copyToClipboard(item['key']!, 'تم نسخ المفتاح'),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
