part of 'main.dart';

class TakvimSayfasi extends StatefulWidget {
  final List<Hatirlatici> hatirlaticilar;
  final List<OzelListe> listeler;
  final Future<void> Function(Hatirlatici) detayAc;
  final Future<void> Function() yeniHatirlatici;

  const TakvimSayfasi({
    super.key,
    required this.hatirlaticilar,
    required this.listeler,
    required this.detayAc,
    required this.yeniHatirlatici,
  });

  @override
  State<TakvimSayfasi> createState() => _TakvimSayfasiState();
}

class _TakvimSayfasiState extends State<TakvimSayfasi> {
  late DateTime ay;
  late DateTime seciliGun;
  bool ayGorunumu = true;

  static const List<String> ayAdlari = <String>[
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

  static const List<String> kisaAyAdlari = <String>[
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    ay = DateTime(now.year, now.month);
    seciliGun = DateTime(now.year, now.month, now.day);
  }

  bool ayniGun(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _gunBaslangici(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<Hatirlatici> remindersFor(DateTime day) {
    final List<Hatirlatici> sonuc = widget.hatirlaticilar
        .where((Hatirlatici h) => ayniGun(h.tarih, day))
        .toList();

    sonuc.sort(
      (Hatirlatici a, Hatirlatici b) => a.tamZaman.compareTo(b.tamZaman),
    );
    return sonuc;
  }

  String _ustTarih() {
    final DateTime now = DateTime.now();
    return 'Bugün, ${now.day} ${kisaAyAdlari[now.month - 1]}';
  }

  String _seciliGunBasligi() {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));

    if (ayniGun(seciliGun, now)) return 'Bugünkü Hatırlatıcılar';
    if (ayniGun(seciliGun, tomorrow)) return 'Yarının Hatırlatıcıları';

    return '${seciliGun.day} ${ayAdlari[seciliGun.month - 1]} Hatırlatıcıları';
  }

  void ayDegistir(int delta) {
    setState(() {
      ay = DateTime(ay.year, ay.month + delta);
      seciliGun = DateTime(ay.year, ay.month, 1);
    });
  }

  void haftaDegistir(int delta) {
    setState(() {
      seciliGun = seciliGun.add(Duration(days: 7 * delta));
      ay = DateTime(seciliGun.year, seciliGun.month);
    });
  }

  Color _hatirlaticiRengi(Hatirlatici h) {
    if (h.tamamlandi) return AppColors.completed;
    if (h.tamZaman.isBefore(DateTime.now())) return AppColors.overdue;

    switch (h.oncelik) {
      case 'Acil':
        return AppColors.overdue;
      case 'Yüksek':
        return AppColors.highPriority;
      case 'Düşük':
        return AppColors.textMuted(Theme.of(context).brightness);
      default:
        return AppColors.primary;
    }
  }

  Widget _ustIkon({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final Brightness brightness = Theme.of(context).brightness;

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 24,
        color: AppColors.textSecondary(brightness),
      ),
    );
  }

  Widget _gorunumSecici() {
    final Brightness brightness = Theme.of(context).brightness;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(brightness),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _gorunumSecenegi(
            baslik: 'Ay',
            secili: ayGorunumu,
            onTap: () => setState(() => ayGorunumu = true),
          ),
          _gorunumSecenegi(
            baslik: 'Hafta',
            secili: !ayGorunumu,
            onTap: () => setState(() => ayGorunumu = false),
          ),
        ],
      ),
    );
  }

  Widget _gorunumSecenegi({
    required String baslik,
    required bool secili,
    required VoidCallback onTap,
  }) {
    final Brightness brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: secili ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          baslik,
          style: AppTextStyles.label.copyWith(
            color: secili
                ? const Color(0xFF071A38)
                : AppColors.textSecondary(brightness),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _takvimKarti() {
    final Brightness brightness = Theme.of(context).brightness;
    final bool mondayFirst = appSettingsNotifier.value.haftaPazartesiBaslar;
    final List<String> weekdays = mondayFirst
        ? <String>['P', 'S', 'Ç', 'P', 'C', 'C', 'P']
        : <String>['P', 'P', 'S', 'Ç', 'P', 'C', 'C'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => ayGorunumu ? ayDegistir(-1) : haftaDegistir(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '${ayAdlari[ay.month - 1]} ${ay.year}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => ayGorunumu ? ayDegistir(1) : haftaDegistir(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (ayGorunumu)
            _ayTakvimi(weekdays)
          else
            _haftaTakvimi(weekdays),
        ],
      ),
    );
  }

  Widget _haftaBasliklari(List<String> weekdays) {
    final Brightness brightness = Theme.of(context).brightness;

    return Row(
      children: weekdays
          .map(
            (String d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted(brightness),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _ayTakvimi(List<String> weekdays) {
    final bool mondayFirst = appSettingsNotifier.value.haftaPazartesiBaslar;
    final int days = DateTime(ay.year, ay.month + 1, 0).day;
    final int firstWeekday = DateTime(ay.year, ay.month, 1).weekday;
    final int leading = mondayFirst ? firstWeekday - 1 : firstWeekday % 7;
    final int totalCells = ((leading + days + 6) ~/ 7) * 7;

    return Column(
      children: <Widget>[
        _haftaBasliklari(weekdays),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.88,
          ),
          itemCount: totalCells,
          itemBuilder: (BuildContext context, int index) {
            final int offsetDay = index - leading + 1;
            final DateTime date = DateTime(ay.year, ay.month, offsetDay);
            final bool inCurrentMonth = date.month == ay.month;
            return _gunHucre(date, inCurrentMonth: inCurrentMonth);
          },
        ),
      ],
    );
  }

  Widget _haftaTakvimi(List<String> weekdays) {
    final bool mondayFirst = appSettingsNotifier.value.haftaPazartesiBaslar;
    final DateTime selectedStart = _gunBaslangici(seciliGun);
    final int weekdayIndex = mondayFirst
        ? selectedStart.weekday - 1
        : selectedStart.weekday % 7;
    final DateTime weekStart = selectedStart.subtract(Duration(days: weekdayIndex));

    return Column(
      children: <Widget>[
        _haftaBasliklari(weekdays),
        const SizedBox(height: 10),
        Row(
          children: List<Widget>.generate(7, (int index) {
            final DateTime date = weekStart.add(Duration(days: index));
            return Expanded(child: _gunHucre(date, inCurrentMonth: true));
          }),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _gunHucre(DateTime date, {required bool inCurrentMonth}) {
    final Brightness brightness = Theme.of(context).brightness;
    final List<Hatirlatici> items = remindersFor(date);
    final bool selected = ayniGun(date, seciliGun);
    final bool today = ayniGun(date, DateTime.now());

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() {
          seciliGun = _gunBaslangici(date);
          if (date.month != ay.month || date.year != ay.year) {
            ay = DateTime(date.year, date.month);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryLight
                    : today
                        ? AppColors.primary.withValues(alpha: 0.13)
                        : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: selected || today
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: !inCurrentMonth
                      ? AppColors.textMuted(brightness).withValues(alpha: 0.42)
                      : selected
                          ? const Color(0xFF0B2A5D)
                          : AppColors.textPrimary(brightness),
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: items.isEmpty
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: items
                          .take(3)
                          .map(
                            (Hatirlatici h) => Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: _hatirlaticiRengi(h),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hatirlaticiKarti(Hatirlatici h) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color accent = _hatirlaticiRengi(h);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await widget.detayAc(h);
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  h.tamamlandi
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 25,
                  color: accent,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            h.baslik,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 17,
                              color: AppColors.textPrimary(brightness),
                              decoration: h.tamamlandi
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          saatMetni(h.saat, h.dakika),
                          style: AppTextStyles.label.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (h.aciklama.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        h.aciklama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: <Widget>[
                        _miniEtiket(
                          icon: Icons.flag_outlined,
                          text: h.oncelik,
                          color: accent,
                        ),
                        if (h.tekrar != 'Tekrar Yok')
                          _miniEtiket(
                            icon: Icons.repeat_rounded,
                            text: h.tekrar,
                            color: AppColors.textSecondary(brightness),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted(brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniEtiket({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final Brightness brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(brightness),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bottomNavTap(int index) async {
    switch (index) {
      case 0:
        if (mounted) {
          Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        }
        break;
      case 1:
        break;
      case 2:
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => IstatistikSayfasi(
              hatirlaticilar: widget.hatirlaticilar,
              listeler: widget.listeler,
              detayAc: widget.detayAc,
              yeniHatirlatici: widget.yeniHatirlatici,
            ),
          ),
        );
        break;
      case 3:
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => AyarlarSayfasi(
              listeler: widget.listeler,
              hatirlaticilar: widget.hatirlaticilar,
              detayAc: widget.detayAc,
              yeniHatirlatici: widget.yeniHatirlatici,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final List<Hatirlatici> selected = remindersFor(seciliGun);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Scrollbar(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            10,
            AppSpacing.screenHorizontal,
            120,
          ),
          children: <Widget>[
            Row(
              children: <Widget>[
                _ustIkon(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Geri',
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    _ustTarih(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary(brightness),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ustIkon(
                  icon: Icons.today_rounded,
                  tooltip: 'Bugüne dön',
                  onPressed: () {
                    final DateTime now = DateTime.now();
                    setState(() {
                      ay = DateTime(now.year, now.month);
                      seciliGun = DateTime(now.year, now.month, now.day);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${ayAdlari[ay.month - 1]} ${ay.year}',
                    style: AppTextStyles.pageTitle.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                ),
                _gorunumSecici(),
              ],
            ),
            const SizedBox(height: 18),
            _takvimKarti(),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _seciliGunBasligi(),
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 22,
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${selected.length}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (selected.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border(brightness).withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.event_available_outlined,
                      size: 38,
                      color: AppColors.textMuted(brightness),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bu gün için hatırlatıcı yok',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary(brightness),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yeni bir hatırlatıcı eklemek için + butonunu kullan.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.metadata.copyWith(
                        color: AppColors.textMuted(brightness),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...selected.map(_hatirlaticiKarti),
          ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: _bottomNavTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await widget.yeniHatirlatici();
          if (mounted) setState(() {});
        },
        tooltip: 'Yeni Hatırlatıcı',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
