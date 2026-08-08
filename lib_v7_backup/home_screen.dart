part of 'main.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with WidgetsBindingObserver {
  final List<Hatirlatici> hatirlaticilar = <Hatirlatici>[];
  final List<OzelListe> ozelListeler = <OzelListe>[];
  bool yukleniyor = true;

  List<OzelListe> get tumListeler => <OzelListe>[
        OzelListe(
          id: defaultListeId,
          ad: 'Hatırlatıcılar',
          renk: 0xFFFF9500,
          iconCode: Icons.format_list_bulleted.codePoint,
        ),
        ...ozelListeler,
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    veriSurumu.addListener(_notificationDataChanged);
    _verileriYukle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    veriSurumu.removeListener(_notificationDataChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verileriYukle(sadeceYenile: true);
    }
  }

  void _notificationDataChanged() {
    _verileriYukle(sadeceYenile: true);
  }

  Future<void> _verileriYukle({bool sadeceYenile = false}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final String? reminderRaw = prefs.getString(hatirlaticilarKey);
      final String? listsRaw = prefs.getString(listelerKey);

      final List<Hatirlatici> reminders = reminderRaw == null ||
              reminderRaw.isEmpty
          ? <Hatirlatici>[]
          : (jsonDecode(reminderRaw) as List<dynamic>)
              .map(
                (dynamic e) => Hatirlatici.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

      final List<OzelListe> lists = listsRaw == null || listsRaw.isEmpty
          ? <OzelListe>[]
          : (jsonDecode(listsRaw) as List<dynamic>)
              .map(
                (dynamic e) => OzelListe.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

      if (!mounted) return;
      setState(() {
        hatirlaticilar
          ..clear()
          ..addAll(reminders);
        ozelListeler
          ..clear()
          ..addAll(lists);
        yukleniyor = false;
      });
    } catch (e) {
      debugPrint('YÜKLEME HATASI: $e');
      if (mounted && !sadeceYenile) {
        setState(() => yukleniyor = false);
      }
    }
  }

  Future<void> _hatirlaticilariKaydet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      hatirlaticilarKey,
      jsonEncode(
        hatirlaticilar.map((Hatirlatici h) => h.toJson()).toList(),
      ),
    );
  }

  Future<void> _listeleriKaydet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      listelerKey,
      jsonEncode(ozelListeler.map((OzelListe l) => l.toJson()).toList()),
    );
  }

  String listeAdi(String id) {
    for (final OzelListe liste in tumListeler) {
      if (liste.id == id) return liste.ad;
    }
    return 'Hatırlatıcılar';
  }

  Color listeRengi(String id) {
    for (final OzelListe liste in tumListeler) {
      if (liste.id == id) return liste.color;
    }
    return Colors.orange;
  }

  bool bugunMu(Hatirlatici h) {
    final DateTime now = DateTime.now();
    return h.tarih.year == now.year &&
        h.tarih.month == now.month &&
        h.tarih.day == now.day;
  }

  bool gecikmisMi(Hatirlatici h) =>
      !h.tamamlandi && h.tamZaman.isBefore(DateTime.now());

  List<Hatirlatici> get bugun => hatirlaticilar
      .where((Hatirlatici h) => !h.tamamlandi && bugunMu(h))
      .toList();

  List<Hatirlatici> get zamanlanmis => hatirlaticilar
      .where(
        (Hatirlatici h) =>
            !h.tamamlandi && h.tamZaman.isAfter(DateTime.now()),
      )
      .toList();

  List<Hatirlatici> get tumu =>
      hatirlaticilar.where((Hatirlatici h) => !h.tamamlandi).toList();

  List<Hatirlatici> get tamamlanan =>
      hatirlaticilar.where((Hatirlatici h) => h.tamamlandi).toList();

  List<Hatirlatici> get gecikmis =>
      hatirlaticilar.where(gecikmisMi).toList();

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

  Future<void> _cancelReminderNotifications(Hatirlatici h) async {
    await _cancelAllForReminderId(h.id);
  }

  tz.TZDateTime _tzDate(DateTime date, int hour, int minute) {
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  tz.TZDateTime _nextDaily(Hatirlatici h) {
    tz.TZDateTime candidate = _tzDate(h.tarih, h.saat, h.dakika);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    while (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  tz.TZDateTime _nextWeekly(Hatirlatici h) {
    tz.TZDateTime candidate = _tzDate(h.tarih, h.saat, h.dakika);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    while (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  tz.TZDateTime _nextMonthly(Hatirlatici h) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    int year = h.tarih.year;
    int month = h.tarih.month;
    final int day = h.tarih.day;

    for (int i = 0; i < 120; i++) {
      final int daysInMonth = DateTime(year, month + 1, 0).day;
      if (day <= daysInMonth) {
        final tz.TZDateTime candidate =
            tz.TZDateTime(tz.local, year, month, day, h.saat, h.dakika);
        if (candidate.isAfter(now)) return candidate;
      }
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    return tz.TZDateTime.now(tz.local).add(const Duration(days: 30));
  }

  tz.TZDateTime _nextWeekday(Hatirlatici h, int targetWeekday) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime candidate = _tzDate(h.tarih, h.saat, h.dakika);

    while (candidate.weekday != targetWeekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  tz.TZDateTime _firstMondayOfMonth(
    int year,
    int month,
    int hour,
    int minute,
  ) {
    tz.TZDateTime candidate = tz.TZDateTime(tz.local, year, month, 1, hour, minute);
    while (candidate.weekday != DateTime.monday) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  Future<void> _scheduleOne({
    required Hatirlatici h,
    required int slot,
    required tz.TZDateTime date,
    DateTimeComponents? match,
  }) async {
    await bildirimPlugin.zonedSchedule(
      id: bildirimId(h.id, slot),
      title: h.baslik,
      body: h.aciklama.trim().isEmpty
          ? 'Hatırlatma zamanı geldi.'
          : h.aciklama,
      scheduledDate: date,
      notificationDetails: _actionNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: match,
      payload: payloadFor(h.id),
    );
  }

  Future<void> bildirimPlanla(Hatirlatici h) async {
    await _cancelReminderNotifications(h);
    if (h.tamamlandi) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    switch (h.tekrar) {
      case 'Her Gün':
        await _scheduleOne(
          h: h,
          slot: 0,
          date: _nextDaily(h),
          match: DateTimeComponents.time,
        );
        break;

      case 'Hafta İçi':
        for (int weekday = DateTime.monday;
            weekday <= DateTime.friday;
            weekday++) {
          await _scheduleOne(
            h: h,
            slot: weekday,
            date: _nextWeekday(h, weekday),
            match: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;

      case 'Seçili Günler':
        for (final int weekday in h.tekrarGunleri) {
          await _scheduleOne(
            h: h,
            slot: 10 + weekday,
            date: _nextWeekday(h, weekday),
            match: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;

      case 'Her Hafta':
        await _scheduleOne(
          h: h,
          slot: 0,
          date: _nextWeekly(h),
          match: DateTimeComponents.dayOfWeekAndTime,
        );
        break;

      case '2 Haftada Bir':
        tz.TZDateTime candidate = _tzDate(h.tarih, h.saat, h.dakika);
        while (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 14));
        }
        for (int i = 0; i < 18; i++) {
          await _scheduleOne(
            h: h,
            slot: 20 + i,
            date: candidate.add(Duration(days: 14 * i)),
          );
        }
        break;

      case 'Her Ay':
        await _scheduleOne(
          h: h,
          slot: 0,
          date: _nextMonthly(h),
          match: DateTimeComponents.dayOfMonthAndTime,
        );
        break;

      case 'Her Ay İlk Pazartesi':
        int year = now.year;
        int month = now.month;
        int slot = 40;
        for (int i = 0; i < 18; i++) {
          final tz.TZDateTime candidate =
              _firstMondayOfMonth(year, month, h.saat, h.dakika);
          if (candidate.isAfter(now)) {
            await _scheduleOne(h: h, slot: slot, date: candidate);
            slot++;
          }
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
        break;

      default:
        final tz.TZDateTime oneTime = _tzDate(h.tarih, h.saat, h.dakika);
        if (oneTime.isAfter(now)) {
          await _scheduleOne(h: h, slot: 0, date: oneTime);
        }
    }
  }

  Future<void> _snoozeAt(
    Hatirlatici h,
    tz.TZDateTime date,
    int slot,
  ) async {
    await bildirimPlugin.zonedSchedule(
      id: bildirimId(h.id, slot),
      title: h.baslik,
      body: h.aciklama.trim().isEmpty
          ? 'Hatırlatma zamanı geldi.'
          : h.aciklama,
      scheduledDate: date,
      notificationDetails: _actionNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payloadFor(h.id),
    );
  }

  Future<void> ertele(Hatirlatici h, String secim) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime target;
    int slot;

    switch (secim) {
      case '30 dk':
        target = now.add(const Duration(minutes: 30));
        slot = 93;
        break;
      case '1 saat':
        target = now.add(const Duration(hours: 1));
        slot = 94;
        break;
      case 'Yarın 09:00':
        final tz.TZDateTime tomorrow = now.add(const Duration(days: 1));
        target = tz.TZDateTime(
          tz.local,
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          9,
          0,
        );
        slot = 95;
        break;
      default:
        target = now.add(const Duration(minutes: 10));
        slot = 92;
    }

    await _snoozeAt(h, target, slot);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${h.baslik} • $secim ertelendi')),
    );
  }

  Future<void> erteleTarihe(Hatirlatici h, DateTime hedef) async {
    final DateTime now = DateTime.now();
    if (!hedef.isAfter(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erteleme zamanı gelecekte olmalı.')),
      );
      return;
    }

    final tz.TZDateTime target = tz.TZDateTime(
      tz.local,
      hedef.year,
      hedef.month,
      hedef.day,
      hedef.hour,
      hedef.minute,
    );
    await _snoozeAt(h, target, 96);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${h.baslik} • ${hedef.day.toString().padLeft(2, '0')}.'
          '${hedef.month.toString().padLeft(2, '0')} ${hedef.hour.toString().padLeft(2, '0')}:'
          '${hedef.minute.toString().padLeft(2, '0')} zamanına ertelendi',
        ),
      ),
    );
  }

  Future<void> altGorevDurumDegistir(
    Hatirlatici h,
    AltGorev g,
    bool value,
  ) async {
    final int reminderIndex =
        hatirlaticilar.indexWhere((Hatirlatici item) => item.id == h.id);
    if (reminderIndex == -1) return;
    final Hatirlatici reminder = hatirlaticilar[reminderIndex];
    final int subIndex =
        reminder.altGorevler.indexWhere((AltGorev item) => item.id == g.id);
    if (subIndex == -1) return;

    bool autoCompleted = false;
    setState(() {
      reminder.altGorevler[subIndex].tamamlandi = value;
      if (reminder.altGorevlerBitinceTamamla &&
          reminder.altGorevler.isNotEmpty &&
          reminder.altGorevler.every((AltGorev item) => item.tamamlandi)) {
        reminder.tamamlandi = true;
        reminder.tamamlanmaTarihi = DateTime.now();
        autoCompleted = true;
      }
    });

    if (autoCompleted) {
      await _cancelReminderNotifications(reminder);
    }
    await _hatirlaticilariKaydet();
  }

  Future<void> zamaniDegistir(Hatirlatici h, DateTime yeniZaman) async {
    final int index =
        hatirlaticilar.indexWhere((Hatirlatici x) => x.id == h.id);
    if (index == -1) return;

    final Hatirlatici updated = h.copyWith(
      tarih: DateTime(yeniZaman.year, yeniZaman.month, yeniZaman.day),
      saat: yeniZaman.hour,
      dakika: yeniZaman.minute,
      tamamlandi: false,
      tamamlanmaTarihiniTemizle: true,
    );

    setState(() => hatirlaticilar[index] = updated);
    await _hatirlaticilariKaydet();
    await bildirimPlanla(updated);
  }

  Future<void> yeniHatirlatici({String? listeId}) async {
    final String hedefListe = listeId ??
        (tumListeler.any(
                (OzelListe l) => l.id == appSettingsNotifier.value.varsayilanListeId)
            ? appSettingsNotifier.value.varsayilanListeId
            : defaultListeId);
    final Hatirlatici? yeni = await Navigator.push<Hatirlatici>(
      context,
      MaterialPageRoute<Hatirlatici>(
        builder: (_) => HatirlaticiDuzenleSayfasi(
          listeler: tumListeler,
          initialListeId: hedefListe,
        ),
      ),
    );

    if (yeni == null) return;
    setState(() => hatirlaticilar.add(yeni));
    await _hatirlaticilariKaydet();
    await bildirimPlanla(yeni);
  }

  Future<void> hatirlaticiDuzenle(Hatirlatici mevcut) async {
    final Hatirlatici? sonuc = await Navigator.push<Hatirlatici>(
      context,
      MaterialPageRoute<Hatirlatici>(
        builder: (_) => HatirlaticiDuzenleSayfasi(
          mevcutHatirlatici: mevcut,
          listeler: tumListeler,
        ),
      ),
    );

    if (sonuc == null) return;
    final int index =
        hatirlaticilar.indexWhere((Hatirlatici h) => h.id == mevcut.id);
    if (index == -1) return;

    await _cancelReminderNotifications(mevcut);
    setState(() => hatirlaticilar[index] = sonuc);
    await _hatirlaticilariKaydet();
    await bildirimPlanla(sonuc);
  }

  Future<void> durumDegistir(Hatirlatici h, bool value) async {
    final int index =
        hatirlaticilar.indexWhere((Hatirlatici x) => x.id == h.id);
    if (index == -1) return;

    setState(() {
      hatirlaticilar[index].tamamlandi = value;
      hatirlaticilar[index].tamamlanmaTarihi = value ? DateTime.now() : null;
    });
    if (value) {
      await _cancelReminderNotifications(hatirlaticilar[index]);
    } else {
      await bildirimPlanla(hatirlaticilar[index]);
    }
    await _hatirlaticilariKaydet();
  }

  Future<void> hatirlaticiSil(Hatirlatici h) async {
    await _cancelReminderNotifications(h);
    setState(
      () => hatirlaticilar.removeWhere((Hatirlatici x) => x.id == h.id),
    );
    await _hatirlaticilariKaydet();
  }

  Future<void> yeniListeOlustur() async {
    final OzelListe? yeni = await showDialog<OzelListe>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const YeniListeDialog(),
    );

    if (!mounted || yeni == null) return;

    setState(() => ozelListeler.add(yeni));
    await _listeleriKaydet();
  }

  Future<void> listeSil(OzelListe liste) async {
    if (liste.id == defaultListeId) return;

    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${liste.ad} silinsin mi?'),
        content: const Text(
          'Bu listedeki hatırlatıcılar Hatırlatıcılar listesine taşınacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    setState(() {
      for (int i = 0; i < hatirlaticilar.length; i++) {
        if (hatirlaticilar[i].listeId == liste.id) {
          hatirlaticilar[i] =
              hatirlaticilar[i].copyWith(listeId: defaultListeId);
        }
      }
      ozelListeler.removeWhere((OzelListe l) => l.id == liste.id);
    });

    await _hatirlaticilariKaydet();
    await _listeleriKaydet();
  }

  Future<void> listeDuzenle(OzelListe liste) async {
    if (liste.id == defaultListeId) return;
    final OzelListe? sonuc = await showDialog<OzelListe>(
      context: context,
      barrierDismissible: false,
      builder: (_) => YeniListeDialog(mevcut: liste),
    );
    if (!mounted || sonuc == null) return;
    final int index = ozelListeler.indexWhere((OzelListe l) => l.id == liste.id);
    if (index == -1) return;
    setState(() => ozelListeler[index] = sonuc);
    await _listeleriKaydet();
  }

  Future<void> listeleriYonetAc() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ListeYonetimSayfasi(
          listeler: ozelListeler,
          onReorder: (int oldIndex, int newIndex) async {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final OzelListe item = ozelListeler.removeAt(oldIndex);
              ozelListeler.insert(newIndex, item);
            });
            await _listeleriKaydet();
          },
          onEdit: listeDuzenle,
          onDelete: listeSil,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> detayAc(Hatirlatici h) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HatirlaticiDetaySayfasi(
          reminderId: h.id,
          anaListe: hatirlaticilar,
          listeAdi: listeAdi,
          listeRengi: listeRengi,
          duzenle: hatirlaticiDuzenle,
          durumDegistir: durumDegistir,
          altGorevDurumDegistir: altGorevDurumDegistir,
          sil: hatirlaticiSil,
          erteleTarihe: erteleTarihe,
          yenidenCiz: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> takvimAc() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TakvimSayfasi(
          hatirlaticilar: hatirlaticilar,
          detayAc: detayAc,
        ),
      ),
    );
  }

  Future<void> istatistikAc() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => IstatistikSayfasi(hatirlaticilar: hatirlaticilar),
      ),
    );
  }

  Future<void> ayarlarAc() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AyarlarSayfasi(listeler: tumListeler),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> aramaAc() async {
    final Hatirlatici? selected = await showSearch<Hatirlatici?>(
      context: context,
      delegate: HatirlaticiAramaDelegate(
        hatirlaticilar: hatirlaticilar,
        listeAdi: listeAdi,
      ),
    );
    if (selected != null && mounted) {
      await detayAc(selected);
    }
  }

  void listeAc(
    String baslik,
    ListeFiltresi filtre, {
    String? listeId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HatirlaticiListeSayfasi(
          baslik: baslik,
          filtre: filtre,
          listeId: listeId,
          anaListe: hatirlaticilar,
          listeAdi: listeAdi,
          listeRengi: listeRengi,
          kaydet: _hatirlaticilariKaydet,
          bildirimPlanla: bildirimPlanla,
          duzenle: hatirlaticiDuzenle,
          durumDegistir: durumDegistir,
          sil: hatirlaticiSil,
          ertele: ertele,
          erteleTarihe: erteleTarihe,
          zamaniDegistir: zamaniDegistir,
          altGorevDurumDegistir: altGorevDurumDegistir,
          detayAc: detayAc,
          yeniHatirlatici: ({String? listeId}) async {
            await yeniHatirlatici(listeId: listeId);
          },
          yenidenCiz: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Widget menuKarti({
    required String baslik,
    required int sayi,
    required IconData ikon,
    required Color renk,
    required VoidCallback onTap,
  }) {
    final Color darker = Color.lerp(renk, Colors.black, 0.27) ?? renk;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[renk, darker],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: renk.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(ikon, size: 25, color: Colors.white),
                ),
                Text(
                  sayi.toString(),
                  style: const TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              baslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gecikmisKarti() {
    return InkWell(
      onTap: () => listeAc('Gecikmiş', ListeFiltresi.gecikmis),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFC84A4A), Color(0xFF8E2E2E)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline, size: 30, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Gecikmiş',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              gecikmis.length.toString(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget listeSatiri(OzelListe liste) {
    final int count = hatirlaticilar
        .where((Hatirlatici h) => !h.tamamlandi && h.listeId == liste.id)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: () => listeAc(
          liste.ad,
          ListeFiltresi.ozelListe,
          listeId: liste.id,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: liste.color,
          child: Icon(liste.icon, color: Colors.white),
        ),
        title: Text(liste.ad, style: const TextStyle(fontSize: 18)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (liste.id != defaultListeId)
              PopupMenuButton<String>(
                onSelected: (String value) async {
                  if (value == 'duzenle') await listeDuzenle(liste);
                  if (value == 'sil') await listeSil(liste);
                },
                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'duzenle',
                    child: Text('Listeyi düzenle'),
                  ),
                  PopupMenuItem<String>(
                    value: 'sil',
                    child: Text('Listeyi sil'),
                  ),
                ],
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.chevron_right, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Hatırlatıcılar',
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: aramaAc,
                          icon: const Icon(Icons.search, size: 27),
                          tooltip: 'Ara',
                        ),
                        IconButton(
                          onPressed: takvimAc,
                          icon: const Icon(Icons.calendar_month_outlined, size: 26),
                          tooltip: 'Takvim',
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, size: 27),
                          onSelected: (String value) async {
                            switch (value) {
                              case 'yeni_liste':
                                await yeniListeOlustur();
                                break;
                              case 'listeler':
                                await listeleriYonetAc();
                                break;
                              case 'istatistik':
                                await istatistikAc();
                                break;
                              case 'ayarlar':
                                await ayarlarAc();
                                break;
                            }
                          },
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem(
                              value: 'yeni_liste',
                              child: ListTile(
                                leading: Icon(Icons.playlist_add),
                                title: Text('Yeni liste'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'listeler',
                              child: ListTile(
                                leading: Icon(Icons.format_list_bulleted),
                                title: Text('Listeleri yönet'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'istatistik',
                              child: ListTile(
                                leading: Icon(Icons.insights_outlined),
                                title: Text('İstatistikler'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'ayarlar',
                              child: ListTile(
                                leading: Icon(Icons.settings_outlined),
                                title: Text('Ayarlar'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.35,
                        children: <Widget>[
                          menuKarti(
                            baslik: 'Bugün',
                            sayi: bugun.length,
                            ikon: Icons.calendar_today,
                            renk: const Color(0xFF438EDB),
                            onTap: () => listeAc('Bugün', ListeFiltresi.bugun),
                          ),
                          menuKarti(
                            baslik: 'Zamanlanmış',
                            sayi: zamanlanmis.length,
                            ikon: Icons.calendar_month,
                            renk: const Color(0xFFE56B73),
                            onTap: () => listeAc(
                              'Zamanlanmış',
                              ListeFiltresi.zamanlanmis,
                            ),
                          ),
                          menuKarti(
                            baslik: 'Tümü',
                            sayi: tumu.length,
                            ikon: Icons.inventory_2_outlined,
                            renk: const Color(0xFF55555A),
                            onTap: () => listeAc('Tümü', ListeFiltresi.tumu),
                          ),
                          menuKarti(
                            baslik: 'Tamamlanan',
                            sayi: tamamlanan.length,
                            ikon: Icons.check_circle_outline,
                            renk: const Color(0xFF818A94),
                            onTap: () => listeAc(
                              'Tamamlanan',
                              ListeFiltresi.tamamlanan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      gecikmisKarti(),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Listelerim',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: yeniListeOlustur,
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'Yeni liste',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...tumListeler.map(listeSatiri),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => yeniHatirlatici(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hatırlatıcı'),
      ),
    );
  }
}

class HatirlaticiAramaDelegate extends SearchDelegate<Hatirlatici?> {
  final List<Hatirlatici> hatirlaticilar;
  final String Function(String id) listeAdi;

  HatirlaticiAramaDelegate({
    required this.hatirlaticilar,
    required this.listeAdi,
  });

  List<Hatirlatici> get sonuc {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return hatirlaticilar;

    return hatirlaticilar.where((Hatirlatici h) {
      final bool subtaskMatch = h.altGorevler.any(
        (AltGorev g) => g.baslik.toLowerCase().contains(q),
      );
      final bool attachmentMatch =
          h.ekler.any((EkDosya e) => e.ad.toLowerCase().contains(q));
      return h.baslik.toLowerCase().contains(q) ||
          h.aciklama.toLowerCase().contains(q) ||
          h.notlar.toLowerCase().contains(q) ||
          h.baglanti.toLowerCase().contains(q) ||
          listeAdi(h.listeId).toLowerCase().contains(q) ||
          h.oncelik.toLowerCase().contains(q) ||
          subtaskMatch ||
          attachmentMatch;
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) => <Widget>[
        if (query.isNotEmpty)
          IconButton(
            onPressed: () => query = '',
            icon: const Icon(Icons.clear),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    if (sonuc.isEmpty) {
      return const Center(child: Text('Sonuç bulunamadı.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sonuc.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Hatirlatici h = sonuc[index];
        return ListTile(
          onTap: () => close(context, h),
          leading: Icon(
            h.tamamlandi ? Icons.check_circle : Icons.circle_outlined,
            color: h.tamamlandi ? Colors.green : Colors.blue,
          ),
          title: Text(h.baslik),
          subtitle: Text(
            '${listeAdi(h.listeId)} • ${h.oncelik} • '
            '${h.tarih.day.toString().padLeft(2, '0')}.'
            '${h.tarih.month.toString().padLeft(2, '0')}.${h.tarih.year}',
          ),
        );
      },
    );
  }
}

