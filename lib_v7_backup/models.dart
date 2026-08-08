part of 'main.dart';

class AppSettings {
  final String tema;
  final int varsayilanErtelemeDakika;
  final String varsayilanListeId;
  final bool haftaPazartesiBaslar;
  final bool saat24;
  final bool bildirimSesi;
  final bool titresim;

  const AppSettings({
    this.tema = 'system',
    this.varsayilanErtelemeDakika = 10,
    this.varsayilanListeId = defaultListeId,
    this.haftaPazartesiBaslar = true,
    this.saat24 = true,
    this.bildirimSesi = true,
    this.titresim = true,
  });

  ThemeMode get themeMode {
    switch (tema) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettings copyWith({
    String? tema,
    int? varsayilanErtelemeDakika,
    String? varsayilanListeId,
    bool? haftaPazartesiBaslar,
    bool? saat24,
    bool? bildirimSesi,
    bool? titresim,
  }) {
    return AppSettings(
      tema: tema ?? this.tema,
      varsayilanErtelemeDakika:
          varsayilanErtelemeDakika ?? this.varsayilanErtelemeDakika,
      varsayilanListeId: varsayilanListeId ?? this.varsayilanListeId,
      haftaPazartesiBaslar:
          haftaPazartesiBaslar ?? this.haftaPazartesiBaslar,
      saat24: saat24 ?? this.saat24,
      bildirimSesi: bildirimSesi ?? this.bildirimSesi,
      titresim: titresim ?? this.titresim,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tema': tema,
        'varsayilanErtelemeDakika': varsayilanErtelemeDakika,
        'varsayilanListeId': varsayilanListeId,
        'haftaPazartesiBaslar': haftaPazartesiBaslar,
        'saat24': saat24,
        'bildirimSesi': bildirimSesi,
        'titresim': titresim,
      };

  static Future<AppSettings> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(ayarlarKey);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      final Map<String, dynamic> json =
          Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return AppSettings(
        tema: json['tema'] as String? ?? 'system',
        varsayilanErtelemeDakika:
            json['varsayilanErtelemeDakika'] as int? ?? 10,
        varsayilanListeId:
            json['varsayilanListeId'] as String? ?? defaultListeId,
        haftaPazartesiBaslar:
            json['haftaPazartesiBaslar'] as bool? ?? true,
        saat24: json['saat24'] as bool? ?? true,
        bildirimSesi: json['bildirimSesi'] as bool? ?? true,
        titresim: json['titresim'] as bool? ?? true,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(ayarlarKey, jsonEncode(toJson()));
    appSettingsNotifier.value = this;
  }
}

class EkDosya {
  final String id;
  final String ad;
  final String path;
  final String tur;

  const EkDosya({
    required this.id,
    required this.ad,
    required this.path,
    required this.tur,
  });

  bool get fotograf => tur == 'foto';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ad': ad,
        'path': path,
        'tur': tur,
      };

  factory EkDosya.fromJson(Map<String, dynamic> json) => EkDosya(
        id: json['id'] as String? ??
            'ek_${DateTime.now().microsecondsSinceEpoch}',
        ad: json['ad'] as String? ?? 'Ek',
        path: json['path'] as String? ?? '',
        tur: json['tur'] as String? ?? 'dosya',
      );
}

Future<DateTime?> modernTarihSec(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
}) async {
  DateTime secili = initial ?? DateTime.now();
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setLocalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Tarih seç',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final DateTime now = DateTime.now();
                          setLocalState(() {
                            secili = DateTime(now.year, now.month, now.day);
                          });
                        },
                        child: const Text('Bugün'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: CalendarDatePicker(
                        initialDate: secili,
                        firstDate: firstDate ?? DateTime(2020),
                        lastDate: DateTime(2045),
                        onDateChanged: (DateTime value) {
                          setLocalState(() => secili = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, secili),
                      child: const Text('Tarihi kullan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<TimeOfDay?> modernSaatSec(
  BuildContext context, {
  TimeOfDay? initial,
}) async {
  final bool use24 = appSettingsNotifier.value.saat24;
  int hour24 = (initial ?? TimeOfDay.now()).hour;
  int minute = (initial ?? TimeOfDay.now()).minute;
  int periodIndex = hour24 >= 12 ? 1 : 0;
  int hourPickerIndex = use24 ? hour24 : ((hour24 % 12 == 0 ? 12 : hour24 % 12) - 1);

  final FixedExtentScrollController hourController =
      FixedExtentScrollController(initialItem: hourPickerIndex);
  final FixedExtentScrollController minuteController =
      FixedExtentScrollController(initialItem: minute);
  final FixedExtentScrollController periodController =
      FixedExtentScrollController(initialItem: periodIndex);

  final TimeOfDay? result = await showModalBottomSheet<TimeOfDay>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setLocalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Saat seç',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        use24 ? '24 saat' : '12 saat',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: hourController,
                            itemExtent: 48,
                            magnification: 1.18,
                            useMagnifier: true,
                            onSelectedItemChanged: (int value) {
                              setLocalState(() {
                                hourPickerIndex = value;
                                if (use24) hour24 = value;
                              });
                            },
                            children: List<Widget>.generate(
                              use24 ? 24 : 12,
                              (int index) => Center(
                                child: Text(
                                  use24
                                      ? index.toString().padLeft(2, '0')
                                      : '${index + 1}',
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Text(':', style: TextStyle(fontSize: 30)),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: minuteController,
                            itemExtent: 48,
                            magnification: 1.18,
                            useMagnifier: true,
                            onSelectedItemChanged: (int value) {
                              setLocalState(() => minute = value);
                            },
                            children: List<Widget>.generate(
                              60,
                              (int index) => Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!use24)
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: periodController,
                              itemExtent: 48,
                              magnification: 1.12,
                              useMagnifier: true,
                              onSelectedItemChanged: (int value) {
                                setLocalState(() => periodIndex = value);
                              },
                              children: const <Widget>[
                                Center(child: Text('ÖÖ', style: TextStyle(fontSize: 22))),
                                Center(child: Text('ÖS', style: TextStyle(fontSize: 22))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (!use24) {
                          final int displayHour = hourPickerIndex + 1;
                          hour24 = displayHour % 12 + (periodIndex == 1 ? 12 : 0);
                        }
                        Navigator.pop(
                          sheetContext,
                          TimeOfDay(hour: hour24, minute: minute),
                        );
                      },
                      child: const Text('Saati kullan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  hourController.dispose();
  minuteController.dispose();
  periodController.dispose();
  return result;
}

class AltGorev {
  final String id;
  final String baslik;
  bool tamamlandi;

  AltGorev({
    required this.id,
    required this.baslik,
    this.tamamlandi = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'baslik': baslik,
        'tamamlandi': tamamlandi,
      };

  factory AltGorev.fromJson(Map<String, dynamic> json) {
    return AltGorev(
      id: json['id'] as String? ??
          'sub_${DateTime.now().microsecondsSinceEpoch}',
      baslik: json['baslik'] as String? ?? '',
      tamamlandi: json['tamamlandi'] as bool? ?? false,
    );
  }

  AltGorev copy() => AltGorev(
        id: id,
        baslik: baslik,
        tamamlandi: tamamlandi,
      );
}

class Hatirlatici {
  final int id;
  final String baslik;
  final String aciklama;
  final DateTime tarih;
  final int saat;
  final int dakika;
  final String tekrar;
  final List<int> tekrarGunleri;
  final String listeId;
  final String oncelik;
  final List<AltGorev> altGorevler;
  final String notlar;
  final String baglanti;
  final List<EkDosya> ekler;
  final bool altGorevlerBitinceTamamla;
  bool tamamlandi;
  DateTime? tamamlanmaTarihi;

  Hatirlatici({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.tarih,
    required this.saat,
    required this.dakika,
    required this.tekrar,
    required this.tekrarGunleri,
    required this.listeId,
    required this.oncelik,
    required this.altGorevler,
    this.notlar = '',
    this.baglanti = '',
    this.ekler = const <EkDosya>[],
    this.altGorevlerBitinceTamamla = false,
    this.tamamlandi = false,
    this.tamamlanmaTarihi,
  });

  DateTime get tamZaman =>
      DateTime(tarih.year, tarih.month, tarih.day, saat, dakika);

  int get tamamlananAltGorevSayisi =>
      altGorevler.where((AltGorev g) => g.tamamlandi).length;

  double get altGorevIlerleme => altGorevler.isEmpty
      ? 0
      : tamamlananAltGorevSayisi / altGorevler.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'baslik': baslik,
        'aciklama': aciklama,
        'tarih': tarih.toIso8601String(),
        'saat': saat,
        'dakika': dakika,
        'tekrar': tekrar,
        'tekrarGunleri': tekrarGunleri,
        'listeId': listeId,
        'oncelik': oncelik,
        'altGorevler': altGorevler.map((AltGorev g) => g.toJson()).toList(),
        'notlar': notlar,
        'baglanti': baglanti,
        'ekler': ekler.map((EkDosya e) => e.toJson()).toList(),
        'altGorevlerBitinceTamamla': altGorevlerBitinceTamamla,
        'tamamlandi': tamamlandi,
        'tamamlanmaTarihi': tamamlanmaTarihi?.toIso8601String(),
      };

  factory Hatirlatici.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSubtasks =
        (json['altGorevler'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> rawDays =
        (json['tekrarGunleri'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> rawAttachments =
        (json['ekler'] as List<dynamic>?) ?? <dynamic>[];

    return Hatirlatici(
      id: (json['id'] as int?) ??
          DateTime.now().microsecondsSinceEpoch.remainder(2147483647),
      baslik: json['baslik'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      tarih: DateTime.parse(json['tarih'] as String),
      saat: json['saat'] as int? ?? 0,
      dakika: json['dakika'] as int? ?? 0,
      tekrar: json['tekrar'] as String? ?? 'Tekrar Yok',
      tekrarGunleri: rawDays.map((dynamic e) => e as int).toList(),
      listeId: json['listeId'] as String? ?? defaultListeId,
      oncelik: json['oncelik'] as String? ?? 'Normal',
      altGorevler: rawSubtasks
          .map((dynamic e) =>
              AltGorev.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      notlar: json['notlar'] as String? ?? '',
      baglanti: json['baglanti'] as String? ?? '',
      ekler: rawAttachments
          .map((dynamic e) =>
              EkDosya.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      altGorevlerBitinceTamamla:
          json['altGorevlerBitinceTamamla'] as bool? ?? false,
      tamamlandi: json['tamamlandi'] as bool? ?? false,
      tamamlanmaTarihi: json['tamamlanmaTarihi'] == null
          ? null
          : DateTime.tryParse(json['tamamlanmaTarihi'] as String),
    );
  }

  Hatirlatici copyWith({
    String? baslik,
    String? aciklama,
    DateTime? tarih,
    int? saat,
    int? dakika,
    String? tekrar,
    List<int>? tekrarGunleri,
    String? listeId,
    String? oncelik,
    List<AltGorev>? altGorevler,
    String? notlar,
    String? baglanti,
    List<EkDosya>? ekler,
    bool? altGorevlerBitinceTamamla,
    bool? tamamlandi,
    DateTime? tamamlanmaTarihi,
    bool tamamlanmaTarihiniTemizle = false,
  }) {
    return Hatirlatici(
      id: id,
      baslik: baslik ?? this.baslik,
      aciklama: aciklama ?? this.aciklama,
      tarih: tarih ?? this.tarih,
      saat: saat ?? this.saat,
      dakika: dakika ?? this.dakika,
      tekrar: tekrar ?? this.tekrar,
      tekrarGunleri: tekrarGunleri ?? List<int>.from(this.tekrarGunleri),
      listeId: listeId ?? this.listeId,
      oncelik: oncelik ?? this.oncelik,
      altGorevler: altGorevler ??
          this.altGorevler.map((AltGorev g) => g.copy()).toList(),
      notlar: notlar ?? this.notlar,
      baglanti: baglanti ?? this.baglanti,
      ekler: ekler ?? List<EkDosya>.from(this.ekler),
      altGorevlerBitinceTamamla:
          altGorevlerBitinceTamamla ?? this.altGorevlerBitinceTamamla,
      tamamlandi: tamamlandi ?? this.tamamlandi,
      tamamlanmaTarihi: tamamlanmaTarihiniTemizle
          ? null
          : (tamamlanmaTarihi ?? this.tamamlanmaTarihi),
    );
  }
}

class OzelListe {
  final String id;
  final String ad;
  final int renk;
  final int iconCode;

  const OzelListe({
    required this.id,
    required this.ad,
    required this.renk,
    required this.iconCode,
  });

  Color get color => Color(renk);
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ad': ad,
        'renk': renk,
        'iconCode': iconCode,
      };

  factory OzelListe.fromJson(Map<String, dynamic> json) {
    return OzelListe(
      id: json['id'] as String,
      ad: json['ad'] as String,
      renk: json['renk'] as int,
      iconCode: json['iconCode'] as int? ?? Icons.list.codePoint,
    );
  }

  OzelListe copyWith({String? ad, int? renk, int? iconCode}) => OzelListe(
        id: id,
        ad: ad ?? this.ad,
        renk: renk ?? this.renk,
        iconCode: iconCode ?? this.iconCode,
      );
}

enum ListeFiltresi {
  bugun,
  zamanlanmis,
  tumu,
  tamamlanan,
  gecikmis,
  ozelListe,
}

