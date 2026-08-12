part of 'main.dart';

enum _StatsPeriod { today, week, month }

class IstatistikSayfasi extends StatefulWidget {
  final List<Hatirlatici> hatirlaticilar;
  final List<OzelListe> listeler;
  final Future<void> Function(Hatirlatici) detayAc;
  final Future<void> Function() yeniHatirlatici;

  const IstatistikSayfasi({
    super.key,
    required this.hatirlaticilar,
    required this.listeler,
    required this.detayAc,
    required this.yeniHatirlatici,
  });

  @override
  State<IstatistikSayfasi> createState() => _IstatistikSayfasiState();
}

class _IstatistikSayfasiState extends State<IstatistikSayfasi> {
  _StatsPeriod _period = _StatsPeriod.week;

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _today => _dayStart(DateTime.now());

  DateTime _weekStart(DateTime d) {
    final DateTime day = _dayStart(d);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime date, DateTime start, DateTime endExclusive) {
    return !date.isBefore(start) && date.isBefore(endExclusive);
  }

  DateTime get _rangeStart {
    switch (_period) {
      case _StatsPeriod.today:
        return _today;
      case _StatsPeriod.week:
        return _weekStart(_today);
      case _StatsPeriod.month:
        return _monthStart(_today);
    }
  }

  DateTime get _rangeEndExclusive {
    switch (_period) {
      case _StatsPeriod.today:
        return _today.add(const Duration(days: 1));
      case _StatsPeriod.week:
        return _rangeStart.add(const Duration(days: 7));
      case _StatsPeriod.month:
        return DateTime(_today.year, _today.month + 1, 1);
    }
  }

  List<Hatirlatici> get _periodTasks => widget.hatirlaticilar.where((h) {
        final DateTime date = DateTime(h.tarih.year, h.tarih.month, h.tarih.day);
        return _inRange(date, _rangeStart, _rangeEndExclusive);
      }).toList();

  int get _completedInPeriod => widget.hatirlaticilar.where((h) {
        final DateTime? date = h.tamamlanmaTarihi;
        return date != null && _inRange(date, _rangeStart, _rangeEndExclusive);
      }).length;

  int get _overdueInPeriod => _periodTasks.where((h) {
        return !h.tamamlandi && h.tamZaman.isBefore(DateTime.now());
      }).length;

  int _completedOn(DateTime day) => widget.hatirlaticilar.where((h) {
        final DateTime? d = h.tamamlanmaTarihi;
        return d != null && _sameDay(d, day);
      }).length;

  int get _subtaskTotal => widget.hatirlaticilar.fold<int>(
        0,
        (sum, h) => sum + h.altGorevler.length,
      );

  int get _subtaskDone => widget.hatirlaticilar.fold<int>(
        0,
        (sum, h) => sum + h.tamamlananAltGorevSayisi,
      );

  double get _completionRate {
    final int relevant = _periodTasks.length;
    if (relevant == 0) return 0;
    final int completed = _periodTasks.where((h) => h.tamamlandi).length;
    return (completed / relevant).clamp(0.0, 1.0);
  }

  String get _periodLabel {
    switch (_period) {
      case _StatsPeriod.today:
        return 'Bugün';
      case _StatsPeriod.week:
        return 'Bu hafta';
      case _StatsPeriod.month:
        return 'Bu ay';
    }
  }


  Future<void> _bottomNavTap(int index) async {
    switch (index) {
      case 0:
        if (mounted) {
          Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        }
        break;
      case 1:
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TakvimSayfasi(
              hatirlaticilar: widget.hatirlaticilar,
              listeler: widget.listeler,
              detayAc: widget.detayAc,
              yeniHatirlatici: widget.yeniHatirlatici,
            ),
          ),
        );
        break;
      case 2:
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
    final Color surface = AppColors.surface(brightness);
    final Color surfaceAlt = AppColors.surfaceAlt(brightness);
    final Color border = AppColors.border(brightness);
    final Color primaryText = AppColors.textPrimary(brightness);
    final Color secondaryText = AppColors.textSecondary(brightness);
    final Color mutedText = AppColors.textMuted(brightness);

    final DateTime today = _today;
    final List<DateTime> last7Days = List<DateTime>.generate(
      7,
      (int i) => today.subtract(Duration(days: 6 - i)),
    );
    final List<int> last7Values = last7Days.map(_completedOn).toList();
    final int maxValue = last7Values.fold<int>(1, (max, value) => value > max ? value : max);

    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  Row(
                    children: <Widget>[
                      _topButton(
                        context,
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'İstatistikler',
                          style: AppTextStyles.pageTitle.copyWith(
                            color: primaryText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _periodLabel,
                          style: AppTextStyles.metadata.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _periodSelector(
                    surface: surface,
                    border: border,
                    primaryText: primaryText,
                    mutedText: mutedText,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _metricCard(
                          context,
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppColors.primaryLight,
                          value: '$_completedInPeriod',
                          label: 'Tamamlanan',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          context,
                          icon: Icons.error_outline_rounded,
                          iconColor: const Color(0xFFFF9696),
                          value: '$_overdueInPeriod',
                          label: 'Gecikmiş',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border.withValues(alpha: 0.55)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Tamamlanma oranı',
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: primaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _completionRate >= 0.75
                                    ? 'Harika gidiyorsun.'
                                    : _completionRate >= 0.40
                                        ? 'İyi ilerliyorsun.'
                                        : 'Küçük adımlarla devam et.',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 14,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        SizedBox(
                          width: 94,
                          height: 94,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: _completionRate,
                                  strokeWidth: 10,
                                  backgroundColor: surfaceAlt,
                                  strokeCap: StrokeCap.round,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryLight,
                                  ),
                                ),
                              ),
                              Text(
                                '%${(_completionRate * 100).round()}',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 21,
                                  color: primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle(
                    'Son 7 gün',
                    'Tamamlanan görevler',
                    primaryText,
                    mutedText,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border.withValues(alpha: 0.55)),
                    ),
                    child: SizedBox(
                      height: 205,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List<Widget>.generate(7, (int index) {
                          final int value = last7Values[index];
                          final DateTime day = last7Days[index];
                          return Expanded(
                            child: _barColumn(
                              day: day,
                              value: value,
                              maxValue: maxValue,
                              selected: _sameDay(day, today),
                              mutedText: mutedText,
                              primaryText: primaryText,
                              surfaceAlt: surfaceAlt,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle(
                    'Alt görev ilerlemesi',
                    'Tüm hatırlatıcılardaki alt görevler',
                    primaryText,
                    mutedText,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border.withValues(alpha: 0.55)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.account_tree_outlined,
                                color: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _subtaskTotal == 0
                                    ? 'Henüz alt görev yok'
                                    : '$_subtaskDone / $_subtaskTotal tamamlandı',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: primaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_subtaskTotal > 0)
                              Text(
                                '%${((_subtaskDone / _subtaskTotal) * 100).round()}',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primaryLight,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _subtaskTotal == 0 ? 0 : _subtaskDone / _subtaskTotal,
                            minHeight: 9,
                            backgroundColor: surfaceAlt,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _insightCard(
                    context,
                    surface: surface,
                    border: border,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),
                ]),
              ),
            ),
          ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: _bottomNavTap,
      ),
    );
  }

  Widget _topButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final Brightness brightness = Theme.of(context).brightness;
    return Material(
      color: AppColors.surface(brightness),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: AppColors.textSecondary(brightness),
          ),
        ),
      ),
    );
  }

  Widget _periodSelector({
    required Color surface,
    required Color border,
    required Color primaryText,
    required Color mutedText,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: <Widget>[
          _periodButton('Bugün', _StatsPeriod.today, primaryText, mutedText),
          _periodButton('Hafta', _StatsPeriod.week, primaryText, mutedText),
          _periodButton('Ay', _StatsPeriod.month, primaryText, mutedText),
        ],
      ),
    );
  }

  Widget _periodButton(
    String label,
    _StatsPeriod period,
    Color primaryText,
    Color mutedText,
  ) {
    final bool selected = _period == period;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _period = period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primaryLight : mutedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final Brightness brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: AppTextStyles.counter.copyWith(
              fontSize: 34,
              color: AppColors.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.metadata.copyWith(
              color: AppColors.textMuted(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
    Color primaryText,
    Color mutedText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.sectionTitle.copyWith(
            fontSize: 21,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppTextStyles.metadata.copyWith(color: mutedText),
        ),
      ],
    );
  }

  Widget _barColumn({
    required DateTime day,
    required int value,
    required int maxValue,
    required bool selected,
    required Color mutedText,
    required Color primaryText,
    required Color surfaceAlt,
  }) {
    const List<String> dayNames = <String>[
      'Pzt',
      'Sal',
      'Çar',
      'Per',
      'Cum',
      'Cmt',
      'Paz',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
            child: Text(
              value == 0 ? '' : '$value',
              style: AppTextStyles.small.copyWith(
                color: selected ? AppColors.primaryLight : mutedText,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double ratio = value == 0 ? 0.05 : value / maxValue;
                final double barHeight = (constraints.maxHeight * ratio)
                    .clamp(8.0, constraints.maxHeight);
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Container(
                      width: 20,
                      decoration: BoxDecoration(
                        color: surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: 20,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primaryLight.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dayNames[day.weekday - 1],
            maxLines: 1,
            style: AppTextStyles.small.copyWith(
              fontSize: 10,
              color: selected ? AppColors.primaryLight : mutedText,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(
    BuildContext context, {
    required Color surface,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final int active = widget.hatirlaticilar.where((h) => !h.tamamlandi).length;
    final int overdue = widget.hatirlaticilar
        .where((h) => !h.tamamlandi && h.tamZaman.isBefore(DateTime.now()))
        .length;

    String insight;
    if (widget.hatirlaticilar.isEmpty) {
      insight = 'İstatistik oluşturmak için birkaç hatırlatıcı ekle.';
    } else if (overdue > 0) {
      insight = '$overdue gecikmiş hatırlatıcın var. Önce bunları temizlemek iyi bir başlangıç olabilir.';
    } else if (active == 0) {
      insight = 'Aktif hatırlatıcı kalmadı. Tüm görevlerini tamamladın.';
    } else if (_completionRate >= 0.75) {
      insight = 'Seçili dönemde görevlerinin büyük bölümünü tamamladın.';
    } else {
      insight = 'Seçili dönemde ${_periodTasks.length} görev bulunuyor. İlerlemeni burada takip edebilirsin.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.highPriority.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.highPriority,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Özet',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  insight,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
