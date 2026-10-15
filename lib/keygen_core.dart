import 'dart:convert';
import 'package:crypto/crypto.dart';

class KeygenCore {
  // نفس المفتاح السري المعتمد في تطبيق المشرفين تماماً
  static const String _secretMasterKey = 'Admin_Net_Controller_MasterSecret_@2026_Yemen!';

  /// التحقق من صيغة المعرف وتصحيحه تلقائياً
  static String? normalizeFingerprint(String input) {
    String clean = input.trim().toUpperCase().replaceAll(' ', '');
    
    // إذا أرسل المستخدم الكود بدون بادئة NET-
    if (!clean.startsWith('NET-')) {
      clean = clean.replaceAll('-', '');
      if (clean.length == 8) {
        clean = 'NET-${clean.substring(0, 4)}-${clean.substring(4, 8)}';
      } else {
        return null;
      }
    }

    final regex = RegExp(r'^NET-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    if (!regex.hasMatch(clean)) {
      return null;
    }
    return clean;
  }

  /// خوارزمية توليد مفتاح التنشيط المتوافقة
  static String generateKey(String normalizedFingerprint) {
    final hmac = Hmac(sha256, utf8.encode(_secretMasterKey));
    final digest = hmac.convert(utf8.encode(normalizedFingerprint)).toString().toUpperCase();

    return 'ACT-${digest.substring(0, 4)}-${digest.substring(8, 12)}-${digest.substring(16, 20)}';
  }
}
