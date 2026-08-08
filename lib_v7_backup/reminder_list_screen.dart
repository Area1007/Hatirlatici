part of 'main.dart';

class HatirlaticiListeSayfasi extends StatefulWidget {
  final String baslik;
  final ListeFiltresi filtre;
  final String? listeId;
  final List<Hatirlatici> anaListe;
  final String Function(String id) listeAdi;
  final Color Function(String id) listeRengi;
  final Future<void> Function() kaydet;
  final Future<void> Function(Hatirlatici) bildirimPlanla;
  final Future<void> Function(Hatirlatici) duzenle;
  final Future<void> Function(Hatirlatici, bool) durumDegistir;
  final Future<void> Function(Hatirlatici) sil;
  final Future<void> Function(Hatirlatici, String) ertele;
  final Future<void> Function(Hatirlatici, DateTime) erteleTarihe;
  final Future<void> Function(Hatirlatici, DateTime) zamaniDegistir;
  final Future<void> Function(Hatirlatici, AltGorev, bool)
      altGorevDurumDegistir;
  final Future<void> Function(Hatirlatici) detayAc;
  final Future<void> Function({String? listeId}) yeniHatirlatici;
  final VoidCallback yenidenCiz;

  const HatirlaticiListeSayfasi({
    super.key,
    required this.baslik,
    required this.filtre,
    required this.listeId,
    required this.anaListe,
    required this.listeAdi,
    required this.listeRengi,
    required this.kaydet,
    required this.bildirimPlanla,
    required this.duzenle,
    required this.durumDegistir,
    required this.sil,
    required this.ertele,
    required this.erteleTarihe,
    required this.zamaniDegistir,
    required this.altGorevDurumDegistir,
    required this.detayAc,
    required this.yeniHatirlatici,
    required this.yenidenCiz,
  });

  @override
  State<HatirlaticiListeSayfasi> createState() =>
      _HatirlaticiListeSayfasiState();
}

class _HatirlaticiListeSayfasiState
    extends State<HatirlaticiListeSayfasi> {
  String filtreOncelik = 'Tümü';
  String filtreListeId = 'Tümü';
  String filtreTarih = 'Tümü';
  String filtreDurum = 'Sayfaya göre';
  String siralama = 'Akıllı';
  bool bugunMu(Hatirlatici h) {
    final DateTime now = DateTime.now();
    return h.tarih.year == now.year &&
        h.tarih.month == now.month &&
        h.tarih.day == now.day;
  }

  bool gecikmisMi(Hatirlatici h) =>
      !h.tamamlandi && h.tamZaman.isBefore(DateTime.now());

  int oncelikPuani(String value) {
    switch (value) {
      case 'Acil':
        return 4;
      case 'Yüksek':
        return 3;
      case 'Normal':
        return 2;
      case 'Düşük':
        return 1;
      default:
        return 2;
    }
  }

  int kategoriPuani(Hatirlatici h) {
    if (gecikmisMi(h)) return 0;
    if (h.oncelik == 'Acil') return 1;
    if (bugunMu(h)) return 2;
    return 3;
  }

  List<Hatirlatici> get liste {
    final DateTime now = DateTime.now();
    List<Hatirlatici> result;

    switch (widget.filtre) {
      case ListeFiltresi.bugun:
        result = widget.anaListe.where(bugunMu).toList();
        break;
      case ListeFiltresi.zamanlanmis:
        result = widget.anaListe
            .where((Hatirlatici h) => h.tamZaman.isAfter(now))
            .toList();
        break;
      case ListeFiltresi.tumu:
        result = List<Hatirlatici>.from(widget.anaListe);
        break;
      case ListeFiltresi.tamamlanan:
        result = List<Hatirlatici>.from(widget.anaListe);
        break;
      case ListeFiltresi.gecikmis:
        result = widget.anaListe
            .where((Hatirlatici h) => h.tamZaman.isBefore(now))
            .toList();
        break;
      case ListeFiltresi.ozelListe:
        result = widget.anaListe
            .where((Hatirlatici h) => h.listeId == widget.listeId)
            .toList();
        break;
    }

    if (filtreDurum == 'Sayfaya göre') {
      if (widget.filtre == ListeFiltresi.tamamlanan) {
        result = result.where((Hatirlatici h) => h.tamamlandi).toList();
      } else {
        result = result.where((Hatirlatici h) => !h.tamamlandi).toList();
      }
    }

    if (filtreOncelik != 'Tümü') {
      result = result
          .where((Hatirlatici h) => h.oncelik == filtreOncelik)
          .toList();
    }
    if (filtreListeId != 'Tümü') {
      result = result
          .where((Hatirlatici h) => h.listeId == filtreListeId)
          .toList();
    }
    if (filtreDurum == 'Aktif') {
      result = result.where((Hatirlatici h) => !h.tamamlandi).toList();
    } else if (filtreDurum == 'Tamamlanan') {
      result = result.where((Hatirlatici h) => h.tamamlandi).toList();
    }

    if (filtreTarih == 'Bugün') {
      result = result.where(bugunMu).toList();
    } else if (filtreTarih == 'Gecikmiş') {
      result = result.where(gecikmisMi).toList();
    } else if (filtreTarih == '7 Gün') {
      final DateTime limit = now.add(const Duration(days: 7));
      result = result
          .where((Hatirlatici h) =>
              !h.tamZaman.isBefore(now) && h.tamZaman.isBefore(limit))
          .toList();
    } else if (filtreTarih == 'Gelecek') {
      result = result
          .where((Hatirlatici h) => h.tamZaman.isAfter(now))
          .toList();
    }

    switch (siralama) {
      case 'Tarih':
        result.sort((Hatirlatici a, Hatirlatici b) =>
            a.tamZaman.compareTo(b.tamZaman));
        break;
      case 'Öncelik':
        result.sort((Hatirlatici a, Hatirlatici b) =>
            oncelikPuani(b.oncelik).compareTo(oncelikPuani(a.oncelik)));
        break;
      case 'A-Z':
        result.sort((Hatirlatici a, Hatirlatici b) =>
            a.baslik.toLowerCase().compareTo(b.baslik.toLowerCase()));
        break;
      default:
        if (widget.filtre == ListeFiltresi.tamamlanan) {
          result.sort((Hatirlatici a, Hatirlatici b) {
            final DateTime ad = a.tamamlanmaTarihi ?? a.tamZaman;
            final DateTime bd = b.tamamlanmaTarihi ?? b.tamZaman;
            return bd.compareTo(ad);
          });
        } else {
          result.sort((Hatirlatici a, Hatirlatici b) {
            final int categoryCompare =
                kategoriPuani(a).compareTo(kategoriPuani(b));
            if (categoryCompare != 0) return categoryCompare;
            final int priorityCompare =
                oncelikPuani(b.oncelik).compareTo(oncelikPuani(a.oncelik));
            if (priorityCompare != 0) return priorityCompare;
            return a.tamZaman.compareTo(b.tamZaman);
          });
        }
    }

    return result;
  }

  String tarihYazisi(Hatirlatici h) {
    return '${h.tarih.day.toString().padLeft(2, '0')}.'
        '${h.tarih.month.toString().padLeft(2, '0')}.${h.tarih.year} • '
        '${saatMetni(h.saat, h.dakika)}';
  }

  Color oncelikRengi(String value) {
    switch (value) {
      case 'Acil':
        return Colors.redAccent;
      case 'Yüksek':
        return Colors.orange;
      case 'Düşük':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<void> _snoozeSheet(Hatirlatici h) async {
    final String? secim = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                title: Text(
                  'Hatırlatıcı işlemleri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Erteleme zamanını kendin seçebilirsin.'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_calendar_outlined),
                title: const Text('Erteleme zamanı seç'),
                subtitle: const Text('Tarih ve saati belirle'),
                onTap: () => Navigator.pop(context, 'ÖZEL'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Düzenle'),
                onTap: () => Navigator.pop(context, 'DÜZENLE'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pop(context, 'SİL'),
              ),
            ],
          ),
        );
      },
    );

    if (secim == null) return;
    if (secim == 'SİL') {
      if (await _silmeOnayi(h)) await widget.sil(h);
    } else if (secim == 'DÜZENLE') {
      await widget.duzenle(h);
    } else if (secim == 'ÖZEL') {
      final DateTime now = DateTime.now();
      final DateTime? date = await modernTarihSec(
        context,
        initial: now,
        firstDate: DateTime(now.year, now.month, now.day),
      );
      if (date == null || !mounted) return;
      final TimeOfDay? time = await modernSaatSec(
        context,
        initial: TimeOfDay.fromDateTime(now.add(
          Duration(minutes: appSettingsNotifier.value.varsayilanErtelemeDakika),
        )),
      );
      if (time == null) return;
      final DateTime target = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      await widget.erteleTarihe(h, target);
    }
    if (mounted) setState(() {});
    widget.yenidenCiz();
  }

  Future<void> _gecikmisAksiyon(Hatirlatici h, String action) async {
    final DateTime now = DateTime.now();
    DateTime target;

    switch (action) {
      case 'Bugün':
        target = DateTime(
          now.year,
          now.month,
          now.day,
          h.saat,
          h.dakika,
        );
        if (!target.isAfter(now)) {
          target = now.add(const Duration(minutes: 5));
        }
        break;
      case 'Yarın':
        final DateTime tomorrow = now.add(const Duration(days: 1));
        target = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          h.saat,
          h.dakika,
        );
        break;
      default:
        target = now.add(const Duration(minutes: 1));
    }

    await widget.zamaniDegistir(h, target);
    if (mounted) setState(() {});
    widget.yenidenCiz();
  }

  Widget _swipeBackground({
    required String action,
    required Alignment alignment,
  }) {
    late final Color color;
    late final IconData icon;
    late final String label;

    switch (action) {
      case 'restore':
        color = Colors.blue;
        icon = Icons.undo;
        label = 'Aktife al';
        break;
      case 'delete':
        color = Colors.redAccent;
        icon = Icons.delete_outline;
        label = 'Sil';
        break;
      case 'snooze':
        color = Colors.orange;
        icon = Icons.snooze;
        label = 'Ertele / Sil';
        break;
      default:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        label = 'Tamamla';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: <Widget>[
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _silmeOnayi(Hatirlatici h) async {
    final bool? sonuc = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hatırlatıcı silinsin mi?'),
          content: Text(
            '“${h.baslik}” kalıcı olarak silinecek.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  Future<void> _tamamlananIslemlerSheet(Hatirlatici h) async {
    final String? secim = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                title: Text(
                  'Tamamlanan hatırlatıcı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.blue),
                title: const Text('Aktife al'),
                subtitle: const Text(
                  'Hatırlatıcıyı yeniden aktif görevlere taşı',
                ),
                onTap: () => Navigator.pop(sheetContext, 'AKTİF'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Sil',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () => Navigator.pop(sheetContext, 'SİL'),
              ),
            ],
          ),
        );
      },
    );

    if (secim == 'AKTİF') {
      await widget.durumDegistir(h, false);
    } else if (secim == 'SİL' && await _silmeOnayi(h)) {
      await widget.sil(h);
    }

    if (mounted) setState(() {});
    widget.yenidenCiz();
  }

  Future<void> _altGorevDurumDegistir(
    Hatirlatici h,
    AltGorev g,
    bool? value,
  ) async {
    if (value == null) return;
    await widget.altGorevDurumDegistir(h, g, value);
    if (mounted) setState(() {});
    widget.yenidenCiz();
  }

  Widget _reminderCard(Hatirlatici h) {
    final bool overdue = gecikmisMi(h);

    final bool completedView =
        widget.filtre == ListeFiltresi.tamamlanan || h.tamamlandi;

    return Dismissible(
      key: ValueKey<String>('reminder_${h.id}_${h.tamamlandi}'),
      background: _swipeBackground(
        action: completedView ? 'restore' : 'complete',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBackground(
        action: completedView ? 'delete' : 'snooze',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          await widget.durumDegistir(h, completedView ? false : true);
          if (mounted) setState(() {});
          widget.yenidenCiz();
          return false;
        }

        if (completedView) {
          if (await _silmeOnayi(h)) {
            await widget.sil(h);
            if (mounted) setState(() {});
            widget.yenidenCiz();
          }
          return false;
        }

        await _snoozeSheet(h);
        return false;
      },
      child: Card(
        color: const Color(0xFF1C1C1E),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await widget.detayAc(h);
            if (mounted) setState(() {});
            widget.yenidenCiz();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Checkbox(
                      value: h.tamamlandi,
                      onChanged: (bool? value) async {
                        if (value == null) return;
                        await widget.durumDegistir(h, value);
                        if (mounted) setState(() {});
                        widget.yenidenCiz();
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  h.baslik,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    decoration: h.tamamlandi
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: oncelikRengi(h.oncelik)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.flag_outlined,
                                      size: 14,
                                      color: oncelikRengi(h.oncelik),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      h.oncelik,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: oncelikRengi(h.oncelik),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (h.aciklama.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              h.aciklama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            tarihYazisi(h),
                            style: TextStyle(
                              color: overdue ? Colors.redAccent : Colors.grey,
                              fontWeight:
                                  overdue ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.circle,
                                size: 9,
                                color: widget.listeRengi(h.listeId),
                              ),
                              Text(widget.listeAdi(h.listeId)),
                              if (h.tekrar != 'Tekrar Yok')
                                Text(
                                  '• ${h.tekrar}',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                            ],
                          ),
                          if (h.altGorevler.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.045),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.checklist,
                                        size: 16,
                                        color: Colors.white60,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Alt görevler • '
                                        '${h.tamamlananAltGorevSayisi}/${h.altGorevler.length}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: LinearProgressIndicator(
                                      value: h.altGorevIlerleme,
                                      minHeight: 5,
                                      backgroundColor: Colors.white10,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  ...h.altGorevler.map(
                                        (AltGorev g) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 5),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Checkbox(
                                                value: g.tamamlandi,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                onChanged: (bool? value) async {
                                                  await _altGorevDurumDegistir(
                                                    h,
                                                    g,
                                                    value,
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  g.baslik,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: g.tamamlandi
                                                        ? Colors.white54
                                                        : Colors.white70,
                                                    decoration: g.tamamlandi
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await widget.duzenle(h);
                        if (mounted) setState(() {});
                        widget.yenidenCiz();
                      },
                      icon: const Icon(Icons.more_horiz),
                      tooltip: 'Düzenle',
                    ),
                  ],
                ),
                if (overdue && !h.tamamlandi) ...<Widget>[
                  const Divider(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ActionChip(
                        avatar: const Icon(Icons.play_arrow, size: 17),
                        label: const Text('Şimdi'),
                        onPressed: () => _gecikmisAksiyon(h, 'Şimdi'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.today, size: 17),
                        label: const Text('Bugüne taşı'),
                        onPressed: () => _gecikmisAksiyon(h, 'Bugün'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.event, size: 17),
                        label: const Text('Yarına ertele'),
                        onPressed: () => _gecikmisAksiyon(h, 'Yarın'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _filtreleriAc() async {
    final List<String> listeIds = widget.anaListe
        .map((Hatirlatici h) => h.listeId)
        .toSet()
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            Widget dropdown(
              String label,
              String value,
              List<DropdownMenuItem<String>> items,
              ValueChanged<String?> onChanged,
            ) {
              return DropdownButtonFormField<String>(
                initialValue: value,
                decoration: InputDecoration(labelText: label),
                items: items,
                onChanged: (String? v) {
                  onChanged(v);
                  setSheetState(() {});
                },
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  18 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Filtrele ve sırala',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 14),
                    dropdown(
                      'Öncelik',
                      filtreOncelik,
                      <String>['Tümü', 'Acil', 'Yüksek', 'Normal', 'Düşük']
                          .map((String v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      (String? v) {
                        if (v != null) filtreOncelik = v;
                      },
                    ),
                    const SizedBox(height: 10),
                    dropdown(
                      'Liste',
                      filtreListeId,
                      <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                        ...listeIds.map(
                          (String id) => DropdownMenuItem(
                            value: id,
                            child: Text(widget.listeAdi(id)),
                          ),
                        ),
                      ],
                      (String? v) {
                        if (v != null) filtreListeId = v;
                      },
                    ),
                    const SizedBox(height: 10),
                    dropdown(
                      'Tarih',
                      filtreTarih,
                      <String>['Tümü', 'Bugün', '7 Gün', 'Gelecek', 'Gecikmiş']
                          .map((String v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      (String? v) {
                        if (v != null) filtreTarih = v;
                      },
                    ),
                    const SizedBox(height: 10),
                    dropdown(
                      'Durum',
                      filtreDurum,
                      <String>['Sayfaya göre', 'Aktif', 'Tamamlanan']
                          .map((String v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      (String? v) {
                        if (v != null) filtreDurum = v;
                      },
                    ),
                    const SizedBox(height: 10),
                    dropdown(
                      'Sıralama',
                      siralama,
                      <String>['Akıllı', 'Tarih', 'Öncelik', 'A-Z']
                          .map((String v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      (String? v) {
                        if (v != null) siralama = v;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              filtreOncelik = 'Tümü';
                              filtreListeId = 'Tümü';
                              filtreTarih = 'Tümü';
                              filtreDurum = 'Sayfaya göre';
                              siralama = 'Akıllı';
                              setSheetState(() {});
                            },
                            child: const Text('Sıfırla'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Uygula'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Hatirlatici> gosterilecekListe = liste;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.baslik,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _filtreleriAc,
            icon: const Icon(Icons.tune),
            tooltip: 'Filtrele ve sırala',
          ),
        ],
      ),
      body: gosterilecekListe.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    widget.filtre == ListeFiltresi.tamamlanan
                        ? 'Henüz tamamlanan hatırlatıcı yok.'
                        : 'Burada henüz hatırlatıcı yok.',
                    style: const TextStyle(fontSize: 17, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gosterilecekListe.length,
              itemBuilder: (BuildContext context, int index) {
                return _reminderCard(gosterilecekListe[index]);
              },
            ),
      floatingActionButton: widget.filtre == ListeFiltresi.ozelListe
          ? FloatingActionButton(
              onPressed: () async {
                await widget.yeniHatirlatici(listeId: widget.listeId);
                if (mounted) setState(() {});
                widget.yenidenCiz();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

