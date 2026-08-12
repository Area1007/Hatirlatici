part of 'main.dart';

class _InlineTemaSecici extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _InlineTemaSecici({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_InlineTemaSecici> createState() => _InlineTemaSeciciState();
}

class _InlineTemaSeciciState extends State<_InlineTemaSecici> {
  bool acik = false;

  String _ad(String value) {
    switch (value) {
      case 'light':
        return 'Açık';
      case 'dark':
        return 'Koyu';
      default:
        return 'Sistem';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    const List<MapEntry<String, String>> secenekler = <MapEntry<String, String>>[
      MapEntry<String, String>('system', 'Sistem'),
      MapEntry<String, String>('light', 'Açık'),
      MapEntry<String, String>('dark', 'Koyu'),
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border(brightness).withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          children: <Widget>[
            _SettingsRow(
              icon: Icons.palette_outlined,
              title: 'Tema',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _ad(widget.value),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary(brightness),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: acik ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted(brightness),
                    ),
                  ),
                ],
              ),
              onTap: () => setState(() => acik = !acik),
            ),
            if (acik) ...<Widget>[
              Divider(
                height: 1,
                color: AppColors.border(brightness).withValues(alpha: 0.5),
              ),
              ...secenekler.map(
                (MapEntry<String, String> item) {
                  final bool selected = widget.value == item.key;
                  return InkWell(
                    onTap: () {
                      widget.onChanged(item.key);
                      setState(() => acik = false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: <Widget>[
                          const SizedBox(width: 42),
                          Expanded(
                            child: Text(
                              item.value,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary(brightness),
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineSecici<T> extends StatefulWidget {
  final IconData icon;
  final String title;
  final T value;
  final String Function(T value) labelBuilder;
  final List<T> options;
  final ValueChanged<T> onChanged;

  const _InlineSecici({
    required this.icon,
    required this.title,
    required this.value,
    required this.labelBuilder,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_InlineSecici<T>> createState() => _InlineSeciciState<T>();
}

class _InlineSeciciState<T> extends State<_InlineSecici<T>> {
  bool acik = false;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border(brightness).withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          children: <Widget>[
            _SettingsRow(
              icon: widget.icon,
              title: widget.title,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      widget.labelBuilder(widget.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary(brightness),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: acik ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted(brightness),
                    ),
                  ),
                ],
              ),
              onTap: () => setState(() => acik = !acik),
            ),
            if (acik) ...<Widget>[
              Divider(
                height: 1,
                color: AppColors.border(brightness).withValues(alpha: 0.5),
              ),
              ...widget.options.map((T option) {
                final bool selected = option == widget.value;
                return InkWell(
                  onTap: () {
                    widget.onChanged(option);
                    setState(() => acik = false);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    child: Row(
                      children: <Widget>[
                        const SizedBox(width: 42),
                        Expanded(
                          child: Text(
                            widget.labelBuilder(option),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary(brightness),
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 21,
                color: AppColors.textMuted(brightness),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary(brightness),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: AppTextStyles.metadata.copyWith(
                        color: AppColors.textMuted(brightness),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: 70,
                color: AppColors.border(brightness).withValues(alpha: 0.45),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(
        title,
        style: AppTextStyles.cardTitle.copyWith(
          color: AppColors.primaryLight,
          fontSize: 19,
        ),
      ),
    );
  }
}

class AyarlarSayfasi extends StatefulWidget {
  final List<OzelListe> listeler;
  final List<Hatirlatici> hatirlaticilar;
  final Future<void> Function(Hatirlatici) detayAc;
  final Future<void> Function() yeniHatirlatici;

  const AyarlarSayfasi({
    super.key,
    required this.listeler,
    required this.hatirlaticilar,
    required this.detayAc,
    required this.yeniHatirlatici,
  });

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  late AppSettings settings;

  @override
  void initState() {
    super.initState();
    settings = appSettingsNotifier.value;
  }

  Future<void> _update(AppSettings value) async {
    setState(() => settings = value);
    await value.save();
  }

  String _listeAdi(String id) {
    for (final OzelListe liste in widget.listeler) {
      if (liste.id == id) return liste.ad;
    }
    return 'Hatırlatıcılar';
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
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    final bool validDefault = widget.listeler.any(
      (OzelListe l) => l.id == settings.varsayilanListeId,
    );

    final String currentList =
        validDefault ? settings.varsayilanListeId : defaultListeId;

    final List<String> listeIds = widget.listeler
        .map((OzelListe l) => l.id)
        .toList();

    if (!listeIds.contains(defaultListeId)) {
      listeIds.insert(0, defaultListeId);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Scrollbar(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 38),
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Geri',
                ),
                const SizedBox(width: 4),
                Text(
                  'Ayarlar',
                  style: AppTextStyles.pageTitle.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const _SectionTitle('Görünüm'),
            _InlineTemaSecici(
              value: settings.tema,
              onChanged: (String value) {
                _update(settings.copyWith(tema: value));
              },
            ),

            const SizedBox(height: 30),

            const _SectionTitle('Genel'),
            _SettingsGroup(
              children: <Widget>[
                _SettingsRow(
                  icon: Icons.schedule_rounded,
                  title: '24 saat biçimi',
                  subtitle: settings.saat24
                      ? 'Saatler 18:30 biçiminde gösterilir'
                      : 'Saatler 6:30 ÖS biçiminde gösterilir',
                  trailing: Switch.adaptive(
                    value: settings.saat24,
                    onChanged: (bool value) {
                      _update(settings.copyWith(saat24: value));
                    },
                  ),
                ),
                _SettingsRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'Hafta Pazartesi başlasın',
                  trailing: Switch.adaptive(
                    value: settings.haftaPazartesiBaslar,
                    onChanged: (bool value) {
                      _update(
                        settings.copyWith(haftaPazartesiBaslar: value),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _InlineSecici<String>(
              icon: Icons.list_alt_rounded,
              title: 'Varsayılan liste',
              value: currentList,
              options: listeIds,
              labelBuilder: _listeAdi,
              onChanged: (String value) {
                _update(settings.copyWith(varsayilanListeId: value));
              },
            ),

            const SizedBox(height: 12),

            _InlineSecici<int>(
              icon: Icons.snooze_rounded,
              title: 'Erteleme süresi',
              value: settings.varsayilanErtelemeDakika,
              options: const <int>[5, 10, 15, 30, 60],
              labelBuilder: (int value) =>
                  value == 60 ? '1 saat' : '$value dakika',
              onChanged: (int value) {
                _update(
                  settings.copyWith(varsayilanErtelemeDakika: value),
                );
              },
            ),

            const SizedBox(height: 30),

            const _SectionTitle('Bildirimler'),
            _SettingsGroup(
              children: <Widget>[
                _SettingsRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Bildirim sesi',
                  subtitle: settings.bildirimSesi ? 'Açık' : 'Kapalı',
                  trailing: Switch.adaptive(
                    value: settings.bildirimSesi,
                    onChanged: (bool value) {
                      _update(settings.copyWith(bildirimSesi: value));
                    },
                  ),
                ),
                _SettingsRow(
                  icon: Icons.vibration_rounded,
                  title: 'Titreşim',
                  subtitle: settings.titresim ? 'Açık' : 'Kapalı',
                  trailing: Switch.adaptive(
                    value: settings.titresim,
                    onChanged: (bool value) {
                      _update(settings.copyWith(titresim: value));
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Text(
              'Hatırlatıcı',
              textAlign: TextAlign.center,
              style: AppTextStyles.metadata.copyWith(
                color: AppColors.textMuted(brightness),
              ),
            ),
          ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: _bottomNavTap,
      ),
    );
  }
}

class ListeYonetimSayfasi extends StatefulWidget {
  final List<OzelListe> listeler;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function(OzelListe liste) onEdit;
  final Future<void> Function(OzelListe liste) onDelete;

  const ListeYonetimSayfasi({
    super.key,
    required this.listeler,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ListeYonetimSayfasi> createState() => _ListeYonetimSayfasiState();
}

class _ListeYonetimSayfasiState extends State<ListeYonetimSayfasi> {
  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 18, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Listeleri Yönet',
                    style: AppTextStyles.pageTitle.copyWith(
                      fontSize: 24,
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border(brightness)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(
                      Icons.format_list_bulleted_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Hatırlatıcılar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('Varsayılan liste • sabit'),
                ),
              ),
            ),
            Expanded(
              child: widget.listeler.isEmpty
                  ? Center(
                      child: Text(
                        'Henüz özel liste yok.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted(brightness),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      buildDefaultDragHandles: false,
                      itemCount: widget.listeler.length,
                      onReorder: (int oldIndex, int newIndex) async {
                        await widget.onReorder(oldIndex, newIndex);
                        if (mounted) setState(() {});
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final OzelListe liste = widget.listeler[index];

                        return Container(
                          key: ValueKey<String>(liste.id),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface(brightness),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border(brightness)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 12,
                              right: 6,
                              top: 3,
                              bottom: 3,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: liste.color,
                              child: Icon(
                                liste.icon,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              liste.ad,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: const Text('Sürükleyerek sırala'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  onPressed: () async {
                                    await widget.onEdit(liste);
                                    if (mounted) setState(() {});
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Düzenle',
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await widget.onDelete(liste);
                                    if (mounted) setState(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  tooltip: 'Sil',
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: AppColors.textMuted(brightness),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
