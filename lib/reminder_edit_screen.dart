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
  bool oncelikAcik = false;

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


  Color _priorityColor(String value) {
    switch (value) {
      case 'Acil':
        return const Color(0xFFFF5B5B);
      case 'Yüksek':
        return const Color(0xFFFFA342);
      case 'Düşük':
        return const Color(0xFF8A93A3);
      default:
        return const Color(0xFF4C8DFF);
    }
  }

  String _dateLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime d = DateTime(date.year, date.month, date.day);
    final int diff = d.difference(today).inDays;
    if (diff == 0) return 'BUGÜN';
    if (diff == 1) return 'YARIN';
    const List<String> days = <String>['PZT','SAL','ÇAR','PER','CUM','CMT','PAZ'];
    return days[d.weekday - 1];
  }

  List<DateTime> get _quickDates {
    final DateTime now = DateTime.now();
    final DateTime base = DateTime(now.year, now.month, now.day);
    return List<DateTime>.generate(5, (int i) => base.add(Duration(days: i)));
  }

  Future<void> _setQuickTime(int hour, int minute) async {
    setState(() => secilenSaat = TimeOfDay(hour: hour, minute: minute));
  }

  Future<void> _setNow() async {
    final DateTime now = DateTime.now();
    setState(() {
      secilenTarih ??= DateTime(now.year, now.month, now.day);
      secilenSaat = TimeOfDay(hour: now.hour, minute: now.minute);
    });
  }

  Future<void> _setOneHourLater() async {
    final DateTime t = DateTime.now().add(const Duration(hours: 1));
    setState(() {
      secilenTarih = DateTime(t.year, t.month, t.day);
      secilenSaat = TimeOfDay(hour: t.hour, minute: t.minute);
    });
  }

  Widget _sectionTitle(String text) {
    final Brightness brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary(brightness),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final Brightness brightness = Theme.of(context).brightness;

    return Material(
      color: AppColors.surface(brightness),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border(brightness).withValues(alpha: 0.55),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _prioritySelector() {
    final Brightness brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => oncelikAcik = !oncelikAcik),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: <Widget>[
                  Icon(Icons.flag_outlined, color: _priorityColor(oncelik)),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'Öncelik',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(brightness),
                      ),
                    ),
                  ),
                  Text(
                    oncelik,
                    style: TextStyle(
                      color: _priorityColor(oncelik),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: oncelikAcik ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary(brightness),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                oncelikAcik ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Column(
              children: oncelikSecenekleri.map((String value) {
                final bool selected = value == oncelik;
                return InkWell(
                  onTap: () => setState(() {
                    oncelik = value;
                    oncelikAcik = false;
                  }),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border(brightness)
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _priorityColor(value),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                              color: AppColors.textPrimary(brightness),
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickTimeButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final Brightness brightness = Theme.of(context).brightness;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border(brightness).withValues(alpha: 0.55),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary(brightness),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary(brightness),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool duzenleme = widget.mevcutHatirlatici != null;
    final DateTime now = DateTime.now();
    final DateTime selectedDateOnly = secilenTarih == null
        ? DateTime(1900)
        : DateTime(secilenTarih!.year, secilenTarih!.month, secilenTarih!.day);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          duzenleme ? 'Hatırlatıcıyı Düzenle' : 'Yeni Hatırlatıcı',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: kaydet,
            child: const Text('Kaydet'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: baslikController,
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(brightness),
              ),
              decoration: const InputDecoration(
                hintText: 'Hatırlatıcı başlığı',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: aciklamaController,
              minLines: 2,
              maxLines: 4,
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                color: AppColors.textPrimary(brightness),
              ),
              decoration: const InputDecoration(
                hintText: 'Açıklama ekle...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 26),

            Row(
              children: <Widget>[
                _sectionTitle('Tarih'),
                const Spacer(),
                TextButton(onPressed: tarihSec, child: const Text('Özel Tarih')),
              ],
            ),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickDates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (BuildContext context, int index) {
                  final DateTime d = _quickDates[index];
                  final DateTime only = DateTime(d.year, d.month, d.day);
                  final bool selected = only == selectedDateOnly;
                  return InkWell(
                    onTap: () => setState(() => secilenTarih = d),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 86,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surface(brightness),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border(brightness)
                                  .withValues(alpha: 0.55),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            _dateLabel(d),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary(brightness),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary(brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Saat'),
            Row(
              children: <Widget>[
                _quickTimeButton(icon: Icons.bolt_rounded, label: 'Şimdi', onTap: _setNow),
                const SizedBox(width: 10),
                _quickTimeButton(icon: Icons.schedule_rounded, label: '1 Saat', onTap: _setOneHourLater),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _quickTimeButton(
                  icon: Icons.wb_sunny_outlined,
                  label: '09:00',
                  selected: secilenSaat?.hour == 9 && secilenSaat?.minute == 0,
                  onTap: () => _setQuickTime(9, 0),
                ),
                const SizedBox(width: 10),
                _quickTimeButton(
                  icon: Icons.nightlight_round,
                  label: '19:00',
                  selected: secilenSaat?.hour == 19 && secilenSaat?.minute == 0,
                  onTap: () => _setQuickTime(19, 0),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.access_time_rounded,
              title: 'Saat seç',
              onTap: saatSec,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    secilenSaat == null ? 'Seçilmedi' : saatMetni(secilenSaat!.hour, secilenSaat!.minute),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textSecondary(brightness),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _sectionTitle('Düzenleme'),
            DropdownButtonFormField<String>(
              initialValue: secilenListeId,
              decoration: const InputDecoration(labelText: 'Liste', prefixIcon: Icon(Icons.list_rounded)),
              items: widget.listeler.map((OzelListe l) => DropdownMenuItem<String>(
                value: l.id,
                child: Row(children: <Widget>[
                  Icon(l.icon, size: 18, color: l.color),
                  const SizedBox(width: 8),
                  Text(l.ad),
                ]),
              )).toList(),
              onChanged: (String? value) {
                if (value != null) setState(() => secilenListeId = value);
              },
            ),
            const SizedBox(height: 12),
            _prioritySelector(),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: tekrar,
              decoration: const InputDecoration(labelText: 'Tekrar', prefixIcon: Icon(Icons.repeat_rounded)),
              items: tekrarSecenekleri.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
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
                spacing: 8,
                runSpacing: 8,
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

            const SizedBox(height: 28),
            _sectionTitle('Alt görevler'),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: altGorevController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => altGorevEkle(),
                    decoration: const InputDecoration(hintText: 'Yeni alt görev', prefixIcon: Icon(Icons.checklist_rounded)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: altGorevEkle, icon: const Icon(Icons.add_rounded)),
              ],
            ),
            if (altGorevler.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alt görevler bitince tamamla'),
                value: altGorevlerBitinceTamamla,
                onChanged: (bool value) => setState(() => altGorevlerBitinceTamamla = value),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border(brightness).withValues(alpha: 0.55),
                  ),
                ),
                child: Column(
                  children: List<Widget>.generate(altGorevler.length, (int index) {
                    final AltGorev g = altGorevler[index];
                    return ListTile(
                      leading: Checkbox(value: g.tamamlandi, onChanged: (bool? value) => setState(() => g.tamamlandi = value ?? false)),
                      title: Text(g.baslik, style: TextStyle(decoration: g.tamamlandi ? TextDecoration.lineThrough : null)),
                      trailing: IconButton(onPressed: () => setState(() => altGorevler.removeAt(index)), icon: const Icon(Icons.close_rounded)),
                    );
                  }),
                ),
              ),
            ],

            const SizedBox(height: 28),
            _sectionTitle('Notlar ve ekler'),
            TextField(
              controller: notlarController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Notlar', prefixIcon: Icon(Icons.notes_rounded)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: baglantiController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Bağlantı', hintText: 'https://...', prefixIcon: Icon(Icons.link_rounded)),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: OutlinedButton.icon(onPressed: fotografEkle, icon: const Icon(Icons.photo_outlined), label: const Text('Fotoğraf'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: dosyaEkle, icon: const Icon(Icons.attach_file_rounded), label: const Text('Dosya'))),
              ],
            ),
            if (ekler.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ekler.map((EkDosya e) => InputChip(
                  avatar: Icon(e.fotograf ? Icons.image_outlined : Icons.insert_drive_file_outlined),
                  label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 180), child: Text(e.ad, overflow: TextOverflow.ellipsis)),
                  onDeleted: () => setState(() => ekler.remove(e)),
                )).toList(),
              ),
            ],

            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: kaydet,
              icon: const Icon(Icons.save_rounded),
              label: Text(duzenleme ? 'Değişiklikleri Kaydet' : 'Hatırlatıcıyı Kaydet'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
          ),
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
    final Brightness brightness = Theme.of(context).brightness;

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
                          : AppColors.surfaceAlt(brightness),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary(brightness),
                    ),
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

