import 'dart:convert';

import 'package:http/http.dart' as http;

class AiReminderResult {
  final String baslik;
  final String aciklama;
  final DateTime tarih;
  final int saat;
  final int dakika;
  final bool saatBelirsiz;
  final String tekrar;
  final String oncelik;
  final double guven;

  const AiReminderResult({
    required this.baslik,
    required this.aciklama,
    required this.tarih,
    required this.saat,
    required this.dakika,
    required this.saatBelirsiz,
    required this.tekrar,
    required this.oncelik,
    required this.guven,
  });

  factory AiReminderResult.fromJson(Map<String, dynamic> json) {
    final List<String> tarihParcalari =
        (json['tarih'] as String).split('-');

    final DateTime tarih = DateTime(
      int.parse(tarihParcalari[0]),
      int.parse(tarihParcalari[1]),
      int.parse(tarihParcalari[2]),
    );

    return AiReminderResult(
      baslik: json['baslik'] as String? ?? 'Hatırlatıcı',
      aciklama: json['aciklama'] as String? ?? '',
      tarih: tarih,
      saat: json['saat'] as int? ?? 9,
      dakika: json['dakika'] as int? ?? 0,
      saatBelirsiz: json['saatBelirsiz'] as bool? ?? false,
      tekrar: json['tekrar'] as String? ?? 'Yok',
      oncelik: json['oncelik'] as String? ?? 'Normal',
      guven: (json['guven'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AiReminderService {
  static const String _baseUrl =
    'https://hatirlatici-backend.onrender.com';

  static Future<AiReminderResult> analizEt(String metin) async {
    final Uri url = Uri.parse(
      '$_baseUrl/api/hatirlatici-coz',
    );

    final http.Response response = await http
        .post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(
            <String, dynamic>{
              'metin': metin,
              'simdikiZaman': DateTime.now().toIso8601String(),
            },
          ),
        )
        .timeout(
          const Duration(seconds: 20),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'AI servisi hata verdi: ${response.statusCode}\n'
        '${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('AI geçersiz yanıt döndürdü.');
    }

    return AiReminderResult.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }
}