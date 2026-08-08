part of 'main.dart';

class _TemaSecici extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TemaSecici({required this.value, required this.onChanged});

  @override
  State<_TemaSecici> createState() => _TemaSeciciState();
}

class _TemaSeciciState extends State<_TemaSecici> {
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    const List<MapEntry<String, String>> secenekler = <MapEntry<String, String>>[
      MapEntry<String, String>('system', 'Sistem'),
      MapEntry<String, String>('light', 'Açık'),
      MapEntry<String, String>('dark', 'Koyu'),
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Tema'),
              subtitle: Text(_ad(widget.value)),
              trailing: AnimatedRotation(
                turns: acik ? .5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.keyboard_arrow_down),
              ),
              onTap: () => setState(() => acik = !acik),
            ),
            if (acik) ...<Widget>[
              const Divider(height: 1),
              ...secenekler.map(
                (MapEntry<String, String> secenek) => RadioListTile<String>(
                  value: secenek.key,
                  groupValue: widget.value,
                  title: Text(secenek.value),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  onChanged: (String? value) {
                    if (value == null) return;
                    widget.onChanged(value);
                    setState(() => acik = false);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AyarlarSayfasi extends StatefulWidget {
  final List<OzelListe> listeler;

  const AyarlarSayfasi({super.key, required this.listeler});

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

  @override
  Widget build(BuildContext context) {
    final bool validDefault =
        widget.listeler.any((OzelListe l) => l.id == settings.varsayilanListeId);
    final String currentList = validDefault
        ? settings.varsayilanListeId
        : defaultListeId;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Görünüm', style: TextStyle(color: Colors.grey)),
          ),
          _TemaSecici(
            value: settings.tema,
            onChanged: (String value) {
              _update(settings.copyWith(tema: value));
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('24 saat biçimi'),
            subtitle: const Text('Örn. 18:30 yerine 6:30 ÖS'),
            value: settings.saat24,
            onChanged: (bool value) => _update(settings.copyWith(saat24: value)),
          ),
          SwitchListTile(
            title: const Text('Hafta Pazartesi başlasın'),
            value: settings.haftaPazartesiBaslar,
            onChanged: (bool value) =>
                _update(settings.copyWith(haftaPazartesiBaslar: value)),
          ),
          const Divider(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Varsayılanlar', style: TextStyle(color: Colors.grey)),
          ),
          DropdownButtonFormField<String>(
            initialValue: currentList,
            decoration: const InputDecoration(
              labelText: 'Varsayılan liste',
              prefixIcon: Icon(Icons.list_alt),
            ),
            items: widget.listeler
                .map(
                  (OzelListe l) => DropdownMenuItem<String>(
                    value: l.id,
                    child: Text(l.ad),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              if (value != null) {
                _update(settings.copyWith(varsayilanListeId: value));
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: settings.varsayilanErtelemeDakika,
            decoration: const InputDecoration(
              labelText: 'Ertelemede önerilen süre',
              prefixIcon: Icon(Icons.snooze),
            ),
            items: <int>[5, 10, 15, 30, 60]
                .map(
                  (int v) => DropdownMenuItem<int>(
                    value: v,
                    child: Text(v == 60 ? '1 saat' : '$v dakika'),
                  ),
                )
                .toList(),
            onChanged: (int? value) {
              if (value != null) {
                _update(settings.copyWith(varsayilanErtelemeDakika: value));
              }
            },
          ),
          const Divider(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Bildirim', style: TextStyle(color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('Bildirim sesi'),
            value: settings.bildirimSesi,
            onChanged: (bool value) =>
                _update(settings.copyWith(bildirimSesi: value)),
          ),
          SwitchListTile(
            title: const Text('Titreşim'),
            value: settings.titresim,
            onChanged: (bool value) => _update(settings.copyWith(titresim: value)),
          ),
        ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Listeleri Yönet')),
      body: Column(
        children: <Widget>[
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.format_list_bulleted, color: Colors.white),
            ),
            title: const Text('Hatırlatıcılar'),
            subtitle: const Text('Varsayılan liste • sabit'),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.listeler.isEmpty
                ? const Center(child: Text('Henüz özel liste yok.'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.listeler.length,
                    onReorder: (int oldIndex, int newIndex) async {
                      await widget.onReorder(oldIndex, newIndex);
                      if (mounted) setState(() {});
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final OzelListe l = widget.listeler[index];
                      return ListTile(
                        key: ValueKey<String>(l.id),
                        leading: CircleAvatar(
                          backgroundColor: l.color,
                          child: Icon(l.icon, color: Colors.white),
                        ),
                        title: Text(l.ad),
                        subtitle: const Text('Sürükleyerek sırala'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              onPressed: () async {
                                await widget.onEdit(l);
                                if (mounted) setState(() {});
                              },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () async {
                                await widget.onDelete(l);
                                if (mounted) setState(() {});
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
