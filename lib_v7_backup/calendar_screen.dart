part of 'main.dart';

class TakvimSayfasi extends StatefulWidget {
  final List<Hatirlatici> hatirlaticilar;
  final Future<void> Function(Hatirlatici) detayAc;

  const TakvimSayfasi({
    super.key,
    required this.hatirlaticilar,
    required this.detayAc,
  });

  @override
  State<TakvimSayfasi> createState() => _TakvimSayfasiState();
}

class _TakvimSayfasiState extends State<TakvimSayfasi> {
  late DateTime ay;
  late DateTime seciliGun;

  static const List<String> ayAdlari = <String>[
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
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

  List<Hatirlatici> remindersFor(DateTime day) => widget.hatirlaticilar
      .where((Hatirlatici h) => ayniGun(h.tarih, day))
      .toList()
    ..sort((Hatirlatici a, Hatirlatici b) => a.tamZaman.compareTo(b.tamZaman));

  void ayDegistir(int delta) {
    setState(() {
      ay = DateTime(ay.year, ay.month + delta);
      seciliGun = DateTime(ay.year, ay.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int days = DateTime(ay.year, ay.month + 1, 0).day;
    final int firstWeekday = DateTime(ay.year, ay.month, 1).weekday;
    final bool mondayFirst = appSettingsNotifier.value.haftaPazartesiBaslar;
    final int leading = mondayFirst ? firstWeekday - 1 : firstWeekday % 7;
    final List<String> weekdays = mondayFirst
        ? <String>['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : <String>['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
    final List<Hatirlatici> selected = remindersFor(seciliGun);

    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => ayDegistir(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${ayAdlari[ay.month - 1]} ${ay.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ayDegistir(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: weekdays
                      .map(
                        (String d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: leading + days,
                  itemBuilder: (BuildContext context, int index) {
                    if (index < leading) return const SizedBox.shrink();
                    final int day = index - leading + 1;
                    final DateTime date = DateTime(ay.year, ay.month, day);
                    final List<Hatirlatici> items = remindersFor(date);
                    final bool selectedDay = ayniGun(date, seciliGun);
                    final bool today = ayniGun(date, DateTime.now());
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => seciliGun = date),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: selectedDay
                              ? Colors.blue
                              : (today
                                  ? Colors.blue.withValues(alpha: 0.14)
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '$day',
                              style: TextStyle(
                                fontWeight:
                                    selectedDay ? FontWeight.bold : FontWeight.normal,
                                color: selectedDay ? Colors.white : null,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (items.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: items
                                    .take(3)
                                    .map(
                                      (Hatirlatici h) => Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: h.tamamlandi
                                              ? Colors.greenAccent
                                              : (selectedDay
                                                  ? Colors.white
                                                  : Colors.blue),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${seciliGun.day.toString().padLeft(2, '0')}.'
            '${seciliGun.month.toString().padLeft(2, '0')}.${seciliGun.year}',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (selected.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Bu gün için hatırlatıcı yok.')),
            )
          else
            ...selected.map(
              (Hatirlatici h) => Card(
                child: ListTile(
                  onTap: () async {
                    await widget.detayAc(h);
                    if (mounted) setState(() {});
                  },
                  leading: Icon(
                    h.tamamlandi ? Icons.check_circle : Icons.circle_outlined,
                    color: h.tamamlandi ? Colors.green : Colors.blue,
                  ),
                  title: Text(h.baslik),
                  subtitle: Text('${saatMetni(h.saat, h.dakika)} • ${h.oncelik}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

