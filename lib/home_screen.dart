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

  Future<void> hizliHatirlaticiAc() async {
    final QuickReminderAction? action =
        await Navigator.push<QuickReminderAction>(
      context,
      FastPageRoute<QuickReminderAction>(
        builder: (_) => const QuickReminderScreen(),
      ),
    );

    if (action == null || !mounted) return;

    final AiReminderResult ai = action.result;

    final String hedefListe = tumListeler.any(
      (OzelListe l) =>
          l.id == appSettingsNotifier.value.varsayilanListeId,
    )
        ? appSettingsNotifier.value.varsayilanListeId
        : defaultListeId;

    final Hatirlatici taslak = Hatirlatici(
      id: DateTime.now().microsecondsSinceEpoch,
      baslik: ai.baslik,
      aciklama: ai.aciklama,
      tarih: DateTime(
        ai.tarih.year,
        ai.tarih.month,
        ai.tarih.day,
      ),
      saat: ai.saat,
      dakika: ai.dakika,
      tekrar: ai.tekrar,
      tekrarGunleri: <int>[],
      listeId: hedefListe,
      oncelik: ai.oncelik,
      altGorevler: <AltGorev>[],
    );

    if (action.detaylariDuzenle) {
      final Hatirlatici? sonuc =
          await Navigator.push<Hatirlatici>(
        context,
        FastPageRoute<Hatirlatici>(
          builder: (_) => HatirlaticiDuzenleSayfasi(
            mevcutHatirlatici: taslak,
            listeler: tumListeler,
          ),
        ),
      );

      if (sonuc == null || !mounted) return;

      setState(() {
        hatirlaticilar.add(sonuc);
      });

      await _hatirlaticilariKaydet();
      await bildirimPlanla(sonuc);
      return;
    }

    setState(() {
      hatirlaticilar.add(taslak);
    });

    await _hatirlaticilariKaydet();
    await bildirimPlanla(taslak);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${taslak.baslik} oluşturuldu.'),
      ),
    );
  }

  Future<void> yeniHatirlaticiSecimiAc() async {
    final Brightness brightness = Theme.of(context).brightness;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface(brightness),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Yeni Hatırlatıcı',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nasıl oluşturmak istediğini seç.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('AI ile oluştur'),
                  subtitle: const Text(
                    '“Yarın saat 5te toplantı” gibi doğal bir cümle yaz.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    hizliHatirlaticiAc();
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.completed.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      color: AppColors.completed,
                    ),
                  ),
                  title: const Text('Normal oluştur'),
                  subtitle: const Text(
                    'Tarih, saat, liste ve diğer ayrıntıları kendin seç.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    yeniHatirlatici();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> yeniHatirlatici({String? listeId}) async {
    final String hedefListe = listeId ??
        (tumListeler.any(
                (OzelListe l) => l.id == appSettingsNotifier.value.varsayilanListeId)
            ? appSettingsNotifier.value.varsayilanListeId
            : defaultListeId);
    final Hatirlatici? yeni = await Navigator.push<Hatirlatici>(
      context,
      FastPageRoute<Hatirlatici>(
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
      FastPageRoute<Hatirlatici>(
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
      FastPageRoute<void>(
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
      FastPageRoute<void>(
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
      FastPageRoute<void>(
        builder: (_) => TakvimSayfasi(
          hatirlaticilar: hatirlaticilar,
          listeler: tumListeler,
          detayAc: detayAc,
          yeniHatirlatici: () => yeniHatirlatici(),
        ),
      ),
    );
  }

  Future<void> istatistikAc() async {
    await Navigator.push<void>(
      context,
      FastPageRoute<void>(
        builder: (_) => IstatistikSayfasi(
          hatirlaticilar: hatirlaticilar,
          listeler: tumListeler,
          detayAc: detayAc,
          yeniHatirlatici: () => yeniHatirlatici(),
        ),
      ),
    );
  }

  Future<void> ayarlarAc() async {
    await Navigator.push<void>(
      context,
      FastPageRoute<void>(
        builder: (_) => AyarlarSayfasi(
          listeler: tumListeler,
          hatirlaticilar: hatirlaticilar,
          detayAc: detayAc,
          yeniHatirlatici: () => yeniHatirlatici(),
        ),
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
      FastPageRoute<void>(
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

  String _anaSayfaTarih() {
    final DateTime now = DateTime.now();

    const List<String> aylar = <String>[
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return 'Bugün, ${now.day} ${aylar[now.month]}';
  }

  String _selamlama() {
    final int saat = DateTime.now().hour;

    if (saat < 6) return 'İyi geceler';
    if (saat < 12) return 'Günaydın';
    if (saat < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  List<Hatirlatici> get _yaklasanHatirlaticilar {
    final List<Hatirlatici> sonuc = hatirlaticilar
        .where((Hatirlatici h) => !h.tamamlandi)
        .toList();

    sonuc.sort((Hatirlatici a, Hatirlatici b) {
      final bool aGecikmis = gecikmisMi(a);
      final bool bGecikmis = gecikmisMi(b);

      if (aGecikmis != bGecikmis) {
        return aGecikmis ? -1 : 1;
      }

      return a.tamZaman.compareTo(b.tamZaman);
    });

    return sonuc.take(5).toList();
  }

  String _kisaTarih(Hatirlatici h) {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));

    if (h.tarih.year == now.year &&
        h.tarih.month == now.month &&
        h.tarih.day == now.day) {
      return 'Bugün';
    }

    if (h.tarih.year == tomorrow.year &&
        h.tarih.month == tomorrow.month &&
        h.tarih.day == tomorrow.day) {
      return 'Yarın';
    }

    return '${h.tarih.day.toString().padLeft(2, '0')}.'
        '${h.tarih.month.toString().padLeft(2, '0')}';
  }

  Widget _ustIkonButonu({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final Brightness brightness = Theme.of(context).brightness;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.55),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(
          icon,
          size: 22,
          color: AppColors.textSecondary(brightness),
        ),
      ),
    );
  }

  Widget _ozetKarti({
    required String baslik,
    required int sayi,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final Brightness brightness = Theme.of(context).brightness;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: AppColors.border(brightness).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    sayi.toString(),
                    style: AppTextStyles.counter.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                baslik,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.textPrimary(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gecikmisYeniKarti() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => listeAc('Gecikmiş', ListeFiltresi.gecikmis),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.overdueDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.overdue.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.overdue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFA5A5),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Gecikmiş',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Dikkat gerektiren hatırlatıcılar',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                gecikmis.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listeKarti(OzelListe liste) {
    final Brightness brightness = Theme.of(context).brightness;

    final int count = hatirlaticilar
        .where(
          (Hatirlatici h) => !h.tamamlandi && h.listeId == liste.id,
        )
        .length;

    return SizedBox(
      width: 156,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => listeAc(
            liste.ad,
            ListeFiltresi.ozelListe,
            listeId: liste.id,
          ),
          onLongPress: liste.id == defaultListeId
              ? null
              : () => listeDuzenle(liste),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border(brightness).withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: liste.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    liste.icon,
                    color: liste.color,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  liste.ad,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 17,
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count görev',
                  style: AppTextStyles.metadata.copyWith(
                    color: AppColors.textMuted(brightness),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _yaklasanKarti(Hatirlatici h) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool overdue = gecikmisMi(h);
    final Color accent = overdue ? AppColors.overdue : listeRengi(h.listeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => detayAc(h),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
          child: Row(
            children: <Widget>[
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => durumDegistir(h, true),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.circle_outlined,
                    color: accent,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      h.baslik,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(brightness),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        if (overdue) ...<Widget>[
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: AppColors.overdue,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            '${_kisaTarih(h)}, '
                            '${h.saat.toString().padLeft(2, '0')}:'
                            '${h.dakika.toString().padLeft(2, '0')}'
                            ' • ${listeAdi(h.listeId)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.metadata.copyWith(
                              color: overdue
                                  ? AppColors.overdue
                                  : AppColors.textMuted(brightness),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => hatirlaticiDuzenle(h),
                tooltip: 'Düzenle',
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textMuted(brightness),
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
    if (yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Brightness brightness = Theme.of(context).brightness;
    final List<Hatirlatici> upNext = _yaklasanHatirlaticilar;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Scrollbar(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            14,
            AppSpacing.screenHorizontal,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _ustIkonButonu(
                    icon: Icons.menu_rounded,
                    tooltip: 'Listeler',
                    onPressed: listeleriYonetAc,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      _anaSayfaTarih(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary(brightness),
                      ),
                    ),
                  ),
                  _ustIkonButonu(
                    icon: Icons.tune_rounded,
                    tooltip: 'Filtre',
                    onPressed: () {
                      listeAc('Tümü', ListeFiltresi.tumu);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ustIkonButonu(
                    icon: Icons.search_rounded,
                    tooltip: 'Ara',
                    onPressed: aramaAc,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                _selamlama(),
                style: AppTextStyles.screenTitle.copyWith(
                  color: AppColors.textPrimary(brightness),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.20,
                children: <Widget>[
                  _ozetKarti(
                    baslik: 'Bugün',
                    sayi: bugun.length,
                    icon: Icons.today_rounded,
                    accent: AppColors.primary,
                    onTap: () => listeAc('Bugün', ListeFiltresi.bugun),
                  ),
                  _ozetKarti(
                    baslik: 'Zamanlanmış',
                    sayi: zamanlanmis.length,
                    icon: Icons.calendar_month_rounded,
                    accent: const Color(0xFF8BA8FF),
                    onTap: () => listeAc(
                      'Zamanlanmış',
                      ListeFiltresi.zamanlanmis,
                    ),
                  ),
                  _ozetKarti(
                    baslik: 'Tümü',
                    sayi: tumu.length,
                    icon: Icons.inventory_2_outlined,
                    accent: const Color(0xFF9A93FF),
                    onTap: () => listeAc('Tümü', ListeFiltresi.tumu),
                  ),
                  _ozetKarti(
                    baslik: 'Tamamlanan',
                    sayi: tamamlanan.length,
                    icon: Icons.check_circle_outline_rounded,
                    accent: AppColors.completed,
                    onTap: () => listeAc(
                      'Tamamlanan',
                      ListeFiltresi.tamamlanan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _gecikmisYeniKarti(),
              const SizedBox(height: 30),
              Row(
                children: <Widget>[
                  Text(
                    'Listelerim',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: yeniListeOlustur,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Yeni'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 154,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tumListeler.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (BuildContext context, int index) {
                    return _listeKarti(tumListeler[index]);
                  },
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: <Widget>[
                  Text(
                    'Sıradakiler',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                  const Spacer(),
                  if (tumu.length > upNext.length)
                    TextButton(
                      onPressed: () => listeAc('Tümü', ListeFiltresi.tumu),
                      child: const Text('Tümünü Gör'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (upNext.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.task_alt_rounded,
                        size: 38,
                        color: AppColors.textMuted(brightness),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Yaklaşan hatırlatıcı yok',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...upNext.map(_yaklasanKarti),
            ],
          ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (int index) async {
          switch (index) {
            case 0:
              break;
            case 1:
              await takvimAc();
              break;
            case 2:
              await istatistikAc();
              break;
            case 3:
              await ayarlarAc();
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: yeniHatirlaticiSecimiAc,
        tooltip: 'Yeni Hatırlatıcı',
        child: const Icon(
          Icons.add_rounded,
          size: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

