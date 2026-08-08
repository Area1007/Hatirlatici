part of 'main.dart';

class HatirlaticiDetaySayfasi extends StatefulWidget {
  final int reminderId;
  final List<Hatirlatici> anaListe;
  final String Function(String id) listeAdi;
  final Color Function(String id) listeRengi;
  final Future<void> Function(Hatirlatici) duzenle;
  final Future<void> Function(Hatirlatici, bool) durumDegistir;
  final Future<void> Function(Hatirlatici, AltGorev, bool)
      altGorevDurumDegistir;
  final Future<void> Function(Hatirlatici) sil;
  final Future<void> Function(Hatirlatici, DateTime) erteleTarihe;
  final VoidCallback yenidenCiz;

  const HatirlaticiDetaySayfasi({
    super.key,
    required this.reminderId,
    required this.anaListe,
    required this.listeAdi,
    required this.listeRengi,
    required this.duzenle,
    required this.durumDegistir,
    required this.altGorevDurumDegistir,
    required this.sil,
    required this.erteleTarihe,
    required this.yenidenCiz,
  });

  @override
  State<HatirlaticiDetaySayfasi> createState() =>
      _HatirlaticiDetaySayfasiState();
}

class _HatirlaticiDetaySayfasiState extends State<HatirlaticiDetaySayfasi> {
  Hatirlatici? get h {
    for (final Hatirlatici item in widget.anaListe) {
      if (item.id == widget.reminderId) return item;
    }
    return null;
  }

  Future<void> _ertele() async {
    final Hatirlatici? current = h;
    if (current == null) return;
    final DateTime now = DateTime.now();
    final DateTime? date = await modernTarihSec(
      context,
      initial: now,
      firstDate: DateTime(now.year, now.month, now.day),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await modernSaatSec(
      context,
      initial: TimeOfDay.fromDateTime(
        now.add(Duration(
          minutes: appSettingsNotifier.value.varsayilanErtelemeDakika,
        )),
      ),
    );
    if (time == null) return;
    await widget.erteleTarihe(
      current,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _sil() async {
    final Hatirlatici? current = h;
    if (current == null) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hatırlatıcı silinsin mi?'),
        content: Text('“${current.baslik}” kalıcı olarak silinecek.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.sil(current);
    widget.yenidenCiz();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _linkAc(String raw) async {
    String value = raw.trim();
    if (value.isEmpty) return;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    final Uri uri = Uri.parse(value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
    }
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Hatirlatici? current = h;
    if (current == null) {
      return const Scaffold(body: Center(child: Text('Hatırlatıcı bulunamadı.')));
    }

    final bool overdue =
        !current.tamamlandi && current.tamZaman.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatıcı Detayı'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) async {
              if (value == 'duzenle') {
                await widget.duzenle(current);
                if (mounted) setState(() {});
              } else if (value == 'ertele') {
                await _ertele();
              } else if (value == 'sil') {
                await _sil();
              }
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'duzenle', child: Text('Düzenle')),
              PopupMenuItem(value: 'ertele', child: Text('Ertele')),
              PopupMenuItem(value: 'sil', child: Text('Sil')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: current.tamamlandi,
                onChanged: (bool? value) async {
                  if (value == null) return;
                  await widget.durumDegistir(current, value);
                  widget.yenidenCiz();
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      current.baslik,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        decoration: current.tamamlandi
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (current.aciklama.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        current.aciklama,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(
                avatar: Icon(
                  Icons.circle,
                  size: 10,
                  color: widget.listeRengi(current.listeId),
                ),
                label: Text(widget.listeAdi(current.listeId)),
              ),
              Chip(
                avatar: const Icon(Icons.flag_outlined, size: 17),
                label: Text(current.oncelik),
              ),
              if (overdue)
                const Chip(
                  avatar: Icon(Icons.error_outline, size: 17),
                  label: Text('Gecikmiş'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _section(
            'Zaman',
            Row(
              children: <Widget>[
                const Icon(Icons.event_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${current.tarih.day.toString().padLeft(2, '0')}.'
                    '${current.tarih.month.toString().padLeft(2, '0')}.${current.tarih.year} • '
                    '${saatMetni(current.saat, current.dakika)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (current.tekrar != 'Tekrar Yok') Text(current.tekrar),
              ],
            ),
          ),
          if (current.altGorevler.isNotEmpty)
            _section(
              'Alt görevler',
              Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${current.tamamlananAltGorevSayisi}/${current.altGorevler.length} tamamlandı',
                        ),
                      ),
                      Text('${(current.altGorevIlerleme * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: current.altGorevIlerleme,
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...current.altGorevler.map(
                    (AltGorev g) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: g.tamamlandi,
                      title: Text(
                        g.baslik,
                        style: TextStyle(
                          decoration:
                              g.tamamlandi ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      onChanged: (bool? value) async {
                        if (value == null) return;
                        await widget.altGorevDurumDegistir(current, g, value);
                        widget.yenidenCiz();
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (current.notlar.trim().isNotEmpty)
            _section('Notlar', Text(current.notlar)),
          if (current.baglanti.trim().isNotEmpty)
            _section(
              'Bağlantı',
              InkWell(
                onTap: () => _linkAc(current.baglanti),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.link, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        current.baglanti,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 18),
                  ],
                ),
              ),
            ),
          if (current.ekler.isNotEmpty)
            _section(
              'Ekler',
              Column(
                children: current.ekler.map((EkDosya e) {
                  if (e.fotograf &&
                      e.path.isNotEmpty &&
                      File(e.path).existsSync()) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(e.path),
                          width: double.infinity,
                          height: 190,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(e.ad),
                    subtitle: const Text('Dosya eki'),
                  );
                }).toList(),
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ertele,
                  icon: const Icon(Icons.snooze),
                  label: const Text('Ertele'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await widget.duzenle(current);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Düzenle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

