part of 'main.dart';

class HatirlaticiDuzenleSayfasi extends StatefulWidget {
  final Hatirlatici? mevcutHatirlatici;
  final List<OzelListe> listeler;
  final String initialListeId;

  const HatirlaticiDuzenleSayfasi({
    super.key,
    this.mevcutHatirlatici,
    required this.listeler,
    this.initialListeId = defaultListeId,
  });

  @override
  State<HatirlaticiDuzenleSayfasi> createState() =>
      _HatirlaticiDuzenleSayfasiState();
}

class _HatirlaticiDuzenleSayfasiState
    extends State<HatirlaticiDuzenleSayfasi> {
  late final TextEditingController baslikController;
  late final TextEditingController aciklamaController;
  late final TextEditingController notlarController;
  late final TextEditingController baglantiController;
  final TextEditingController altGorevController = TextEditingController();

  DateTime? secilenTarih;
  TimeOfDay? secilenSaat;
  String tekrar = 'Tekrar Yok';
  late String secilenListeId;
  String oncelik = 'Normal';
  List<int> tekrarGunleri = <int>[];
  final List<AltGorev> altGorevler = <AltGorev>[];
  final List<EkDosya> ekler = <EkDosya>[];
  bool altGorevlerBitinceTamamla = false;

  static const List<String> tekrarSecenekleri = <String>[
    'Tekrar Yok',
    'Her Gün',
    'Hafta İçi',
    'Seçili Günler',
    'Her Hafta',
    '2 Haftada Bir',
    'Her Ay',
    'Her Ay İlk Pazartesi',
  ];

  static const List<String> oncelikSecenekleri = <String>[
    'Düşük',
    'Normal',
    'Yüksek',
    'Acil',
  ];

  static const Map<int, String> gunAdlari = <int, String>{
    DateTime.monday: 'Pzt',
    DateTime.tuesday: 'Sal',
    DateTime.wednesday: 'Çar',
    DateTime.thursday: 'Per',
    DateTime.friday: 'Cum',
    DateTime.saturday: 'Cmt',
    DateTime.sunday: 'Paz',
  };

  @override
  void initState() {
    super.initState();
    final Hatirlatici? h = widget.mevcutHatirlatici;

    baslikController = TextEditingController(text: h?.baslik ?? '');
    aciklamaController = TextEditingController(text: h?.aciklama ?? '');
    notlarController = TextEditingController(text: h?.notlar ?? '');
    baglantiController = TextEditingController(text: h?.baglanti ?? '');
    secilenListeId = h?.listeId ?? widget.initialListeId;

    if (!widget.listeler.any((OzelListe l) => l.id == secilenListeId)) {
      secilenListeId = defaultListeId;
    }

    if (h != null) {
      secilenTarih = h.tarih;
      secilenSaat = TimeOfDay(hour: h.saat, minute: h.dakika);
      tekrar = tekrarSecenekleri.contains(h.tekrar) ? h.tekrar : 'Tekrar Yok';
      oncelik = oncelikSecenekleri.contains(h.oncelik) ? h.oncelik : 'Normal';
      tekrarGunleri = List<int>.from(h.tekrarGunleri);
      altGorevler.addAll(h.altGorevler.map((AltGorev g) => g.copy()));
      ekler.addAll(h.ekler);
      altGorevlerBitinceTamamla = h.altGorevlerBitinceTamamla;
    }
  }

  Future<void> tarihSec() async {
    final DateTime now = DateTime.now();
    final DateTime? tarih = await modernTarihSec(
      context,
      initial: secilenTarih ?? now,
      firstDate: widget.mevcutHatirlatici == null
          ? DateTime(now.year, now.month, now.day)
          : DateTime(2020),
    );
    if (tarih != null) setState(() => secilenTarih = tarih);
  }

  Future<void> saatSec() async {
    final TimeOfDay? saat = await modernSaatSec(
      context,
      initial: secilenSaat ?? TimeOfDay.now(),
    );
    if (saat != null) setState(() => secilenSaat = saat);
  }

  Future<void> fotografEkle() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;
    setState(() {
      ekler.add(
        EkDosya(
          id: 'ek_${DateTime.now().microsecondsSinceEpoch}',
          ad: file.name,
          path: file.path,
          tur: 'foto',
        ),
      );
    });
  }

  Future<void> dosyaEkle() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final PlatformFile file = result.files.single;
    if (file.path == null) return;
    setState(() {
      ekler.add(
        EkDosya(
          id: 'ek_${DateTime.now().microsecondsSinceEpoch}',
          ad: file.name,
          path: file.path!,
          tur: 'dosya',
        ),
      );
    });
  }

  void altGorevEkle() {
    final String text = altGorevController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      altGorevler.add(
        AltGorev(
          id: 'sub_${DateTime.now().microsecondsSinceEpoch}',
          baslik: text,
        ),
      );
      altGorevController.clear();
    });
  }

  void kaydet() {
    final String baslik = baslikController.text.trim();
    if (baslik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir başlık gir.')),
      );
      return;
    }

    if (secilenTarih == null || secilenSaat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih ve saat seç.')),
      );
      return;
    }

    if (tekrar == 'Seçili Günler' && tekrarGunleri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir tekrar günü seç.')),
      );
      return;
    }

    final Hatirlatici? eski = widget.mevcutHatirlatici;
    final int id = eski?.id ??
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    Navigator.pop(
      context,
      Hatirlatici(
        id: id,
        baslik: baslik,
        aciklama: aciklamaController.text.trim(),
        tarih: secilenTarih!,
        saat: secilenSaat!.hour,
        dakika: secilenSaat!.minute,
        tekrar: tekrar,
        tekrarGunleri: List<int>.from(tekrarGunleri),
        listeId: secilenListeId,
        oncelik: oncelik,
        altGorevler: altGorevler.map((AltGorev g) => g.copy()).toList(),
        notlar: notlarController.text.trim(),
        baglanti: baglantiController.text.trim(),
        ekler: List<EkDosya>.from(ekler),
        altGorevlerBitinceTamamla: altGorevlerBitinceTamamla,
        tamamlandi: eski?.tamamlandi ?? false,
        tamamlanmaTarihi: eski?.tamamlanmaTarihi,
      ),
    );
  }

  @override
  void dispose() {
    baslikController.dispose();
    aciklamaController.dispose();
    notlarController.dispose();
    baglantiController.dispose();
    altGorevController.dispose();
    super.dispose();
  }

  Widget bolumBasligi(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool duzenleme = widget.mevcutHatirlatici != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          duzenleme ? 'Hatırlatıcıyı Düzenle' : 'Yeni Hatırlatıcı',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: baslikController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'Örn: Proje raporunu tamamla',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: aciklamaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notlarController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notlar',
                hintText: 'Detaylı notlarını buraya yaz',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: baglantiController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Bağlantı',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: fotografEkle,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Fotoğraf'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: dosyaEkle,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Dosya'),
                  ),
                ),
              ],
            ),
            if (ekler.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ekler.map((EkDosya e) {
                  return InputChip(
                    avatar: Icon(e.fotograf ? Icons.image_outlined : Icons.insert_drive_file_outlined),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(e.ad, overflow: TextOverflow.ellipsis),
                    ),
                    onDeleted: () => setState(() => ekler.remove(e)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 22),
            bolumBasligi('Düzenleme'),
            DropdownButtonFormField<String>(
              initialValue: secilenListeId,
              decoration: const InputDecoration(
                labelText: 'Liste',
                prefixIcon: Icon(Icons.list),
              ),
              items: widget.listeler
                  .map(
                    (OzelListe l) => DropdownMenuItem<String>(
                      value: l.id,
                      child: Row(
                        children: <Widget>[
                          Icon(l.icon, size: 18, color: l.color),
                          const SizedBox(width: 8),
                          Text(l.ad),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value != null) setState(() => secilenListeId = value);
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: oncelik,
              decoration: const InputDecoration(
                labelText: 'Öncelik',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: oncelikSecenekleri
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value != null) setState(() => oncelik = value);
              },
            ),
            const SizedBox(height: 22),
            bolumBasligi('Zaman'),
            ListTile(
              tileColor: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: const Icon(Icons.calendar_month),
              title: const Text('Tarih'),
              subtitle: Text(
                secilenTarih == null
                    ? 'Tarih seçilmedi'
                    : '${secilenTarih!.day.toString().padLeft(2, '0')}.'
                        '${secilenTarih!.month.toString().padLeft(2, '0')}.'
                        '${secilenTarih!.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: tarihSec,
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: const Icon(Icons.access_time),
              title: const Text('Saat'),
              subtitle: Text(
                secilenSaat == null
                    ? 'Saat seçilmedi'
                    : saatMetni(secilenSaat!.hour, secilenSaat!.minute),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: saatSec,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: tekrar,
              decoration: const InputDecoration(
                labelText: 'Tekrar',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: tekrarSecenekleri
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    tekrar = value;
                    if (tekrar != 'Seçili Günler') tekrarGunleri.clear();
                  });
                }
              },
            ),
            if (tekrar == 'Seçili Günler') ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: gunAdlari.entries.map((MapEntry<int, String> entry) {
                  return FilterChip(
                    label: Text(entry.value),
                    selected: tekrarGunleri.contains(entry.key),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          tekrarGunleri.add(entry.key);
                        } else {
                          tekrarGunleri.remove(entry.key);
                        }
                        tekrarGunleri.sort();
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 22),
            bolumBasligi('Alt görevler'),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: altGorevController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => altGorevEkle(),
                    decoration: const InputDecoration(
                      hintText: 'Yeni alt görev',
                      prefixIcon: Icon(Icons.checklist),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: altGorevEkle,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (altGorevler.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Alt görevler bitince ana görevi tamamla'),
                subtitle: const Text('Son alt görev işaretlenince hatırlatıcı tamamlanır.'),
                value: altGorevlerBitinceTamamla,
                onChanged: (bool value) {
                  setState(() => altGorevlerBitinceTamamla = value);
                },
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: List<Widget>.generate(
                    altGorevler.length,
                    (int index) {
                      final AltGorev g = altGorevler[index];
                      return ListTile(
                        leading: Checkbox(
                          value: g.tamamlandi,
                          onChanged: (bool? value) {
                            setState(() => g.tamamlandi = value ?? false);
                          },
                        ),
                        title: Text(
                          g.baslik,
                          style: TextStyle(
                            decoration: g.tamamlandi
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () =>
                              setState(() => altGorevler.removeAt(index)),
                          icon: const Icon(Icons.close),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: kaydet,
              icon: const Icon(Icons.save),
              label: Text(
                duzenleme ? 'Değişiklikleri Kaydet' : 'Hatırlatıcıyı Kaydet',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class YeniListeDialog extends StatefulWidget {
  final OzelListe? mevcut;

  const YeniListeDialog({super.key, this.mevcut});

  @override
  State<YeniListeDialog> createState() => _YeniListeDialogState();
}

class _YeniListeDialogState extends State<YeniListeDialog> {
  late final TextEditingController _controller;

  static const List<Color> _renkler = <Color>[
    Colors.orange,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.red,
    Colors.indigo,
  ];

  static const List<IconData> _ikonlar = <IconData>[
    Icons.list,
    Icons.school_outlined,
    Icons.work_outline,
    Icons.person_outline,
    Icons.shopping_cart_outlined,
    Icons.flight_outlined,
    Icons.fitness_center_outlined,
    Icons.home_outlined,
    Icons.code_outlined,
    Icons.star_outline,
  ];

  Color _secilenRenk = _renkler.first;
  IconData _secilenIkon = _ikonlar.first;
  bool _kapatiliyor = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.mevcut?.ad ?? '');
    if (widget.mevcut != null) {
      _secilenRenk = widget.mevcut!.color;
      _secilenIkon = widget.mevcut!.icon;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _iptal() {
    if (_kapatiliyor) return;
    _kapatiliyor = true;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  void _olustur() {
    if (_kapatiliyor) return;

    final String ad = _controller.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste adı boş olamaz.')),
      );
      return;
    }

    _kapatiliyor = true;
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      OzelListe(
        id: widget.mevcut?.id ??
            'list_${DateTime.now().microsecondsSinceEpoch}',
        ad: ad,
        renk: _secilenRenk.toARGB32(),
        iconCode: _secilenIkon.codePoint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.mevcut == null ? 'Yeni Liste' : 'Listeyi Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _olustur(),
              decoration: const InputDecoration(
                labelText: 'Liste adı',
                hintText: 'Örn: Okul',
              ),
            ),
            const SizedBox(height: 18),
            const Text('Renk'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _renkler.map((Color color) {
                final bool selected = color == _secilenRenk;
                return GestureDetector(
                  onTap: _kapatiliyor
                      ? null
                      : () => setState(() => _secilenRenk = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('İkon'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _ikonlar.map((IconData icon) {
                final bool selected = icon.codePoint == _secilenIkon.codePoint;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _kapatiliyor
                      ? null
                      : () => setState(() => _secilenIkon = icon),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? _secilenRenk
                          : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _kapatiliyor ? null : _iptal,
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _kapatiliyor ? null : _olustur,
          child: Text(widget.mevcut == null ? 'Oluştur' : 'Kaydet'),
        ),
      ],
    );
  }
}

String saatMetni(int hour, int minute) {
  if (appSettingsNotifier.value.saat24) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final String period = hour < 12 ? 'ÖÖ' : 'ÖS';
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

