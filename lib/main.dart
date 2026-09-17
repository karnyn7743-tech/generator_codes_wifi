import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KeyGenApp());
}

// ============================================================
// === التطبيق ===
// ============================================================
class KeyGenApp extends StatelessWidget {
  const KeyGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LanPhone KeyGen',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.system,
      home: const KeyGenScreen(),
    );
  }

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F7B6C),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F7B6C),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F1418),
  );
}

// ============================================================
// === الشاشة الرئيسية ===
// ============================================================
class KeyGenScreen extends StatefulWidget {
  const KeyGenScreen({super.key});

  @override
  State<KeyGenScreen> createState() => _KeyGenScreenState();
}

class _KeyGenScreenState extends State<KeyGenScreen> {
  // ============================================
  // === المراجع ===
  // ============================================
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final FocusNode _deviceIdFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // ============================================
  // === الحالة ===
  // ============================================
  String? _generatedKey;
  String? _generatedForDevice;
  String? _errorMessage;
  List<Map<String, dynamic>> _history = [];
  bool _batchMode = false;
  List<Map<String, String>> _batchResults = [];

  // ============================================
  // === السرّ (يجب أن يطابق LanPhone) ===
  // ============================================

  static const List<String> _secretPartA = [
    'Lan',
    'Phone',
    '-Act',
    '-A1',
    '-2024',
    '-7kXz',
  ];

  static const List<String> _secretPartB = [
    'Lp',
    'Sec',
    '-B2',
    '-2024',
    '-9mNq',
  ];

  static const String _appIdentifier = 'com.lanphone.app.v1';

  static String get _secretA => _secretPartA.join();
  static String get _secretB => _secretPartB.join();

  // ============================================
  // === دورة الحياة ===
  // ============================================

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _batchController.dispose();
    _deviceIdFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================
  // === توليد المفتاح (نفس منطق LanPhone) ===
  // ============================================

  String generateKey(String deviceId) {
    final layer1 = sha256
        .convert(utf8.encode('$deviceId:$_secretA'))
        .toString();

    final layer2 = sha256
        .convert(utf8.encode('$layer1:$_appIdentifier:$_secretB'))
        .toString();

    final hex = layer2.toUpperCase();
    final part = hex.substring(0, 16);

    return '${part.substring(0, 4)}-'
        '${part.substring(4, 8)}-'
        '${part.substring(8, 12)}-'
        '${part.substring(12, 16)}';
  }

  // ============================================
  // === توليد فردي ===
  // ============================================

  void _generateSingle() {
    final deviceId = _deviceIdController.text.trim();

    if (deviceId.isEmpty) {
      setState(() {
        _errorMessage = 'الصق معرّف الجهاز أولًا';
        _generatedKey = null;
      });
      return;
    }

    // تحقق: هل يبدأ بـ ANDROID- أو IOS-؟
    if (!deviceId.startsWith('ANDROID-') &&
        !deviceId.startsWith('IOS-') &&
        !deviceId.startsWith('UNKNOWN-')) {
      setState(() {
        _errorMessage =
            'المعرّف يجب أن يبدأ بـ ANDROID- أو IOS-';
        _generatedKey = null;
      });
      return;
    }

    final key = generateKey(deviceId);

    setState(() {
      _generatedKey = key;
      _generatedForDevice = deviceId;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();
    _saveToHistory(deviceId, key);
  }

  // ============================================
  // === توليد جماعي ===
  // ============================================

  void _generateBatch() {
    final input = _batchController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'الصق قائمة المعرّفات (واحد لكل سطر)';
        _batchResults = [];
      });
      return;
    }

    final lines = input
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final results = <Map<String, String>>[];

    for (final deviceId in lines) {
      if (deviceId.startsWith('ANDROID-') ||
          deviceId.startsWith('IOS-') ||
          deviceId.startsWith('UNKNOWN-')) {
        results.add({
          'deviceId': deviceId,
          'key': generateKey(deviceId),
        });
      } else {
        results.add({
          'deviceId': deviceId,
          'key': 'خطأ: معرّف غير صالح',
        });
      }
    }

    setState(() {
      _batchResults = results;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    // احفظ الكل في السجل
    for (final r in results) {
      if (!r['key']!.startsWith('خطأ')) {
        _saveToHistory(r['deviceId']!, r['key']!);
      }
    }
  }

  // ============================================
  // === السجل ===
  // ============================================

  static const String _keyHistory = 'keygen_history';

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyHistory);
      if (raw == null) return;

      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _history = list);
    } catch (_) {}
  }

  Future<void> _saveToHistory(String deviceId, String key) async {
    try {
      // تجنّب التكرار
      _history.removeWhere((h) => h['deviceId'] == deviceId);

      _history.insert(0, {
        'deviceId': deviceId,
        'key': key,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // احتفظ بآخر 50 مفتاح
      if (_history.length > 50) {
        _history = _history.sublist(0, 50);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyHistory, jsonEncode(_history));

      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح السجل'),
        content: const Text('هل تريد حذف كل السجل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
    if (mounted) setState(() => _history = []);
  }

  // ============================================
  // === أدوات ===
  // ============================================

  Future<void> _pasteDeviceId() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;

    _deviceIdController.text = text;
    _deviceIdFocus.requestFocus();
    setState(() {});
  }

  Future<void> _copyKey(String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    if (!mounted) return;
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ المفتاح: $key'),
        backgroundColor: const Color(0xFF43A047),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyAllBatch() async {
    final buffer = StringBuffer();
    for (final r in _batchResults) {
      buffer.writeln('${r['deviceId']}');
      buffer.writeln('   → ${r['key']}');
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ كل النتائج'),
        backgroundColor: Color(0xFF43A047),
      ),
    );
  }

  // ============================================
  // === الواجهة ===
  // ============================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LanPhone KeyGen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1C2227) : const Color(0xFF0F7B6C),
        foregroundColor: Colors.white,
        actions: [
          // تبديل الوضع
          IconButton(
            icon: Icon(_batchMode ? Icons.person : Icons.people),
            tooltip: _batchMode ? 'توليد فردي' : 'توليد جماعي',
            onPressed: () {
              setState(() {
                _batchMode = !_batchMode;
                _errorMessage = null;
                _generatedKey = null;
                _batchResults = [];
              });
            },
          ),
          // مسح السجل
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'مسح السجل',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // ============================================
          // === رأس توضيحي ===
          // ============================================
          _buildHeader(isDark),

          const SizedBox(height: 20),

          // ============================================
          // === وضع التوليد ===
          // ============================================
          _batchMode
              ? _buildBatchMode(isDark)
              : _buildSingleMode(isDark),

          const SizedBox(height: 24),

          // ============================================
          // === السجل ===
          // ============================================
          if (_history.isNotEmpty) _buildHistorySection(isDark),
        ],
      ),
    );
  }

  // ============================================
  // === رأس ===
  // ============================================

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F7B6C).withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0F7B6C).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF0F7B6C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.vpn_key,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _batchMode ? 'توليد جماعي' : 'توليد فردي',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F7B6C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _batchMode
                      ? 'الصق قائمة معرّفات (واحد لكل سطر)'
                      : 'الصق معرّف الجهاز من شاشة التنشيط',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white70
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // === الوضع الفردي ===
  // ============================================

  Widget _buildSingleMode(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ============================================
        // === حقل الإدخال ===
        // ============================================
        TextField(
          controller: _deviceIdController,
          focusNode: _deviceIdFocus,
          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            labelText: 'معرّف الجهاز',
            hintText: 'ANDROID-xxxxxxxxxxxxxxxx',
            hintStyle: const TextStyle(fontFamily: 'monospace'),
            prefixIcon: const Icon(Icons.phone_android),
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste),
              tooltip: 'لصق',
              onPressed: _pasteDeviceId,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C2227) : Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // ============================================
        // === زر التوليد ===
        // ============================================
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: _generateSingle,
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'توليد المفتاح',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F7B6C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ============================================
        // === رسالة الخطأ ===
        // ============================================
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ============================================
        // === النتيجة ===
        // ============================================
        if (_generatedKey != null) ...[
          const SizedBox(height: 4),
          _buildResultCard(
            deviceId: _generatedForDevice ?? '',
            key: _generatedKey!,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  // ============================================
  // === بطاقة النتيجة ===
  // ============================================

  Widget _buildResultCard({
    required String deviceId,
    required String key,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F7B6C), Color(0xFF25D366)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F7B6C).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'تم التوليد بنجاح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // المفتاح
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              key,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'monospace',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // الجهاز
          Text(
            'الجهاز:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            deviceId,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // زر النسخ
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _copyKey(key),
              icon: const Icon(Icons.copy, size: 20),
              label: const Text('نسخ المفتاح'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F7B6C),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // === الوضع الجماعي ===
  // ============================================

  Widget _buildBatchMode(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _batchController,
          maxLines: 6,
          minLines: 4,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: 'قائمة المعرّفات',
            hintText: 'ANDROID-xxx\nANDROID-yyy\nANDROID-zzz',
            hintStyle: const TextStyle(fontFamily: 'monospace'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C2227) : Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: _generateBatch,
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'توليد الكل',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F7B6C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),

        // النتائج
        if (_batchResults.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'النتائج (${_batchResults.length}):',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _copyAllBatch,
                icon: const Icon(Icons.copy_all, size: 18),
                label: const Text('نسخ الكل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._batchResults.map((r) => _buildBatchResult(r, isDark)),
        ],
      ],
    );
  }

  Widget _buildBatchResult(Map<String, String> result, bool isDark) {
    final isError = result['key']!.startsWith('خطأ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withOpacity(0.1)
            : isDark
                ? const Color(0xFF1C2227)
                : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? Colors.red.withOpacity(0.3)
              : isDark
                  ? const Color(0xFF2A3138)
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result['deviceId']!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  result['key']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                    color: isError
                        ? Colors.red
                        : const Color(0xFF0F7B6C),
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isError)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => _copyKey(result['key']!),
            ),
        ],
      ),
    );
  }

  // ============================================
  // === قسم السجل ===
  // ============================================

  Widget _buildHistorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 18),
            const SizedBox(width: 8),
            const Text(
              'السجل',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${_history.length} مفتاح',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._history.map((h) => _buildHistoryItem(h, isDark)),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2227) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3138) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['deviceId'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  item['key'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                    color: Color(0xFF0F7B6C),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => _copyKey(item['key'] as String),
          ),
        ],
      ),
    );
  }
}
