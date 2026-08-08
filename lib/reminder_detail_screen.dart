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

  Brightness get _brightness => Theme.of(context).brightness;

  Color get _surface => AppColors.surface(_brightness);
  Color get _surfaceAlt => AppColors.surfaceAlt(_brightness);
  Color get _border => AppColors.border(_brightness);
  Color get _textPrimary => AppColors.textPrimary(_brightness);
  Color get _textSecondary => AppColors.textSecondary(_brightness);
  Color get _textMuted => AppColors.textMuted(_brightness);

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
        now.add(
          Duration(
            minutes: appSettingsNotifier.value.varsayilanErtelemeDakika,
          ),
        ),
      ),
    );

    if (time == null) return;

    await widget.erteleTarihe(
      current,
      DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
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
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.overdue,
              foregroundColor: Colors.white,
            ),
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

  Future<void> _duzenle() async {
    final Hatirlatici? current = h;
    if (current == null) return;
    await widget.duzenle(current);
    if (mounted) setState(() {});
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

  String _tarihMetni(Hatirlatici current) {
    const List<String> aylar = <String>[
      '',
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

    return '${current.tarih.day} ${aylar[current.tarih.month]} '
        '${current.tarih.year} • ${saatMetni(current.saat, current.dakika)}';
  }

  Color _oncelikRengi(String oncelik) {
    switch (oncelik) {
      case 'Acil':
        return AppColors.overdue;
      case 'Yüksek':
        return AppColors.highPriority;
      case 'Düşük':
        return AppColors.completed;
      default:
        return AppColors.primary;
    }
  }

  Widget _ikonButon({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _border.withValues(alpha: 0.55),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: _textSecondary),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            text,
            style: AppTextStyles.metadata.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    IconData? icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: _border.withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: 11),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    color: _textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _altGorevler(Hatirlatici current) {
    final int completed = current.tamamlananAltGorevSayisi;
    final int total = current.altGorevler.length;
    final int percent = (current.altGorevIlerleme * 100).round();

    return _sectionCard(
      title: 'Alt Görevler',
      icon: Icons.checklist_rounded,
      trailing: Text(
        '$completed/$total',
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: current.altGorevIlerleme,
                    minHeight: 8,
                    backgroundColor: _surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: AppTextStyles.metadata.copyWith(
                  color: _textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...current.altGorevler.map(
            (AltGorev g) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await widget.altGorevDurumDegistir(
                    current,
                    g,
                    !g.tamamlandi,
                  );
                  widget.yenidenCiz();
                  if (mounted) setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: g.tamamlandi
                              ? AppColors.completed
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: g.tamamlandi
                                ? AppColors.completed
                                : _textMuted,
                            width: 1.7,
                          ),
                        ),
                        child: g.tamamlandi
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g.baslik,
                          style: AppTextStyles.body.copyWith(
                            color: g.tamamlandi ? _textMuted : _textPrimary,
                            decoration: g.tamamlandi
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ekler(Hatirlatici current) {
    return _sectionCard(
      title: 'Ekler',
      icon: Icons.attach_file_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          current.ekler.length.toString(),
          style: AppTextStyles.small.copyWith(color: _textSecondary),
        ),
      ),
      child: Column(
        children: current.ekler.map((EkDosya e) {
          if (e.fotograf && e.path.isNotEmpty && File(e.path).existsSync()) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(e.path),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.insert_drive_file_outlined,
                  color: _textSecondary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    e.ad,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final Color effectiveColor = color ?? _textSecondary;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 22, color: effectiveColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.w700,
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
    final Hatirlatici? current = h;

    if (current == null) {
      return const Scaffold(
        body: Center(child: Text('Hatırlatıcı bulunamadı.')),
      );
    }

    final bool overdue =
        !current.tamamlandi && current.tamZaman.isBefore(DateTime.now());
    final Color listColor = widget.listeRengi(current.listeId);
    final Color priorityColor = _oncelikRengi(current.oncelik);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Scrollbar(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  14,
                  AppSpacing.screenHorizontal,
                  24,
                ),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _ikonButon(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Geri',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _ikonButon(
                        icon: Icons.edit_outlined,
                        tooltip: 'Düzenle',
                        onPressed: _duzenle,
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Diğer',
                        color: _surface,
                        onSelected: (String value) async {
                          if (value == 'ertele') await _ertele();
                          if (value == 'sil') await _sil();
                        },
                        itemBuilder: (_) => const <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'ertele',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.snooze_rounded),
                              title: Text('Ertele'),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'sil',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.overdue,
                              ),
                              title: Text(
                                'Sil',
                                style: TextStyle(color: AppColors.overdue),
                              ),
                            ),
                          ),
                        ],
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _border.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () async {
                          await widget.durumDegistir(
                            current,
                            !current.tamamlandi,
                          );
                          widget.yenidenCiz();
                          if (mounted) setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3, right: 13),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: current.tamamlandi
                                  ? AppColors.completed
                                  : Colors.transparent,
                              border: Border.all(
                                width: 2,
                                color: current.tamamlandi
                                    ? AppColors.completed
                                    : (overdue
                                        ? AppColors.overdue
                                        : AppColors.primary),
                              ),
                            ),
                            child: current.tamamlandi
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              current.baslik,
                              style: AppTextStyles.screenTitle.copyWith(
                                fontSize: 31,
                                color: _textPrimary,
                                decoration: current.tamamlandi
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (current.aciklama.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 10),
                              Text(
                                current.aciklama,
                                style: AppTextStyles.body.copyWith(
                                  color: _textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _chip(
                        icon: Icons.calendar_today_outlined,
                        text: _tarihMetni(current),
                        color: overdue ? AppColors.overdue : AppColors.primary,
                      ),
                      _chip(
                        icon: Icons.flag_outlined,
                        text: current.oncelik,
                        color: priorityColor,
                      ),
                      _chip(
                        icon: Icons.folder_outlined,
                        text: widget.listeAdi(current.listeId),
                        color: listColor,
                      ),
                      _chip(
                        icon: Icons.repeat_rounded,
                        text: current.tekrar == 'Tekrar Yok'
                            ? 'Tekrarlamaz'
                            : current.tekrar,
                        color: _textSecondary,
                      ),
                      if (overdue)
                        _chip(
                          icon: Icons.error_outline_rounded,
                          text: 'Gecikmiş',
                          color: AppColors.overdue,
                        ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  if (current.altGorevler.isNotEmpty) _altGorevler(current),

                  if (current.notlar.trim().isNotEmpty)
                    _sectionCard(
                      title: 'Notlar',
                      icon: Icons.notes_rounded,
                      child: Text(
                        current.notlar,
                        style: AppTextStyles.body.copyWith(
                          color: _textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),

                  if (current.baglanti.trim().isNotEmpty)
                    _sectionCard(
                      title: 'Bağlantı',
                      icon: Icons.link_rounded,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _linkAc(current.baglanti),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.public_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  current.baglanti,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (current.ekler.isNotEmpty) _ekler(current),

                  const SizedBox(height: 10),
                ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(
                14,
                10,
                14,
                10 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: _surface,
                border: Border(
                  top: BorderSide(
                    color: _border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  _bottomAction(
                    icon: Icons.edit_outlined,
                    label: 'Düzenle',
                    onTap: _duzenle,
                    color: AppColors.primary,
                  ),
                  _bottomAction(
                    icon: Icons.snooze_rounded,
                    label: 'Ertele',
                    onTap: _ertele,
                  ),
                  _bottomAction(
                    icon: current.tamamlandi
                        ? Icons.undo_rounded
                        : Icons.check_circle_outline_rounded,
                    label: current.tamamlandi ? 'Geri Al' : 'Tamamla',
                    onTap: () async {
                      await widget.durumDegistir(
                        current,
                        !current.tamamlandi,
                      );
                      widget.yenidenCiz();
                      if (mounted) setState(() {});
                    },
                    color: AppColors.completed,
                  ),
                  _bottomAction(
                    icon: Icons.delete_outline_rounded,
                    label: 'Sil',
                    onTap: _sil,
                    color: AppColors.overdue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
