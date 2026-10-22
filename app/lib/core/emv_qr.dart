/// EMVCo QR payload parser.
///
/// Both NEPALPAY QR and FonePay QR are EMVCo merchant-presented payloads:
/// a string of TLV (tag-length-value) fields. This parser extracts what the
/// confirm sheet needs: scheme, merchant name/city, amount (if dynamic),
/// currency (524 = NPR), and the merchant account identifier (MAI).
class EmvQr {
  final Map<String, String> root;
  final String scheme; // 'NEPALPAY', 'FONEPAY', or 'UNKNOWN'
  final String? merchantName;
  final String? merchantCity;
  final double? amount; // null for static QR (user enters amount)
  final String currencyCode; // '524' = NPR
  final String? merchantAccountId;

  const EmvQr({
    required this.root,
    required this.scheme,
    this.merchantName,
    this.merchantCity,
    this.amount,
    this.currencyCode = '524',
    this.merchantAccountId,
  });

  bool get isDynamic => amount != null;

  static Map<String, String> _parseTlv(String s) {
    final out = <String, String>{};
    var i = 0;
    while (i + 4 <= s.length) {
      final tag = s.substring(i, i + 2);
      final len = int.tryParse(s.substring(i + 2, i + 4)) ?? 0;
      if (i + 4 + len > s.length) break;
      out[tag] = s.substring(i + 4, i + 4 + len);
      i += 4 + len;
    }
    return out;
  }

  /// Returns null if the payload is not a plausible EMVCo QR.
  static EmvQr? tryParse(String raw) {
    if (raw.length < 20 || !raw.startsWith('00')) return null;
    final root = _parseTlv(raw);
    if (root['00'] != '01') return null; // payload format indicator

    // Merchant Account Information lives in tags 02..51. Nepal schemes:
    // NEPALPAY QR payloads carry the NepalQR GUI inside the MAI template;
    // FonePay QR carries FonePay's GUI. We detect by content, and also read
    // the nested name/id subfields (subtag 00 = GUI, 01 = merchant id).
    String scheme = 'UNKNOWN';
    String? mai;
    for (var t = 2; t <= 51; t++) {
      final tag = t.toString().padLeft(2, '0');
      final v = root[tag];
      if (v == null) continue;
      final lower = v.toLowerCase();
      if (lower.contains('nepalpay') || lower.contains('nqr')) {
        scheme = 'NEPALPAY';
      } else if (lower.contains('fonepay') || lower.contains('f1soft')) {
        scheme = 'FONEPAY';
      }
      final nested = _parseTlv(v);
      mai = nested['01'] ?? nested['02'] ?? mai;
      if (scheme != 'UNKNOWN') break;
    }

    final additional = root['62'] != null ? _parseTlv(root['62']!) : const <String, String>{};
    return EmvQr(
      root: root,
      scheme: scheme,
      merchantName: root['59'] ?? additional['07'],
      merchantCity: root['60'],
      amount: root['54'] != null ? double.tryParse(root['54']!) : null,
      currencyCode: root['53'] ?? '524',
      merchantAccountId: mai,
    );
  }
}
