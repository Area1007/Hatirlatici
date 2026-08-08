part of 'main.dart';

class IstatistikSayfasi extends StatelessWidget {
  final List<Hatirlatici> hatirlaticilar;

  const IstatistikSayfasi({super.key, required this.hatirlaticilar});

  int _completedOn(DateTime day) => hatirlaticilar.where((Hatirlatici h) {
        final DateTime? d = h.tamamlanmaTarihi;
        return d != null &&
            d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).length;

  @override
  Widget build(BuildContext context) {
    final int total = hatirlaticilar.length;
    final int completed =
        hatirlaticilar.where((Hatirlatici h) => h.tamamlandi).length;
    final int active = total - completed;
    final int overdue = hatirlaticilar
        .where((Hatirlatici h) =>
            !h.tamamlandi && h.tamZaman.isBefore(DateTime.now()))
        .length;
    final double rate = total == 0 ? 0 : completed / total;
    final int subTotal = hatirlaticilar.fold<int>(
      0,
      (int sum, Hatirlatici h) => sum + h.altGorevler.length,
    );
    final int subDone = hatirlaticilar.fold<int>(
      0,
      (int sum, Hatirlatici h) => sum + h.tamamlananAltGorevSayisi,
    );

    final DateTime today = DateTime.now();
    final List<DateTime> days = List<DateTime>.generate(
      7,
      (int i) => DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i)),
    );
    final List<int> values = days.map(_completedOn).toList();
    final int maxValue = values.isEmpty
        ? 1
        : values
            .reduce((int a, int b) => a > b ? a : b)
            .clamp(1, 999)
            .toInt();

    Widget statCard(String title, String value, IconData icon, Color color) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
        children: <Widget>[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: <Widget>[
              statCard('Aktif', '$active', Icons.pending_actions, Colors.blue),
              statCard('Tamamlanan', '$completed', Icons.check_circle, Colors.green),
              statCard('Gecikmiş', '$overdue', Icons.warning_amber, Colors.redAccent),
              statCard(
                'Tamamlanma oranı',
                '%${(rate * 100).round()}',
                Icons.donut_large,
                Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Son 7 gün',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 185,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List<Widget>.generate(7, (int index) {
                      final int value = values[index];
                      final double height = 14 + (100 * value / maxValue);
                      const List<String> names = <String>[
                        'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'
                      ];
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text('$value', style: const TextStyle(fontSize: 11)),
                            const SizedBox(height: 4),
                            Container(
                              width: 22,
                              height: height,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              names[days[index].weekday - 1],
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            leading: const Icon(Icons.checklist),
            title: const Text('Alt görev ilerlemesi'),
            subtitle: LinearProgressIndicator(
              value: subTotal == 0 ? 0 : subDone / subTotal,
            ),
            trailing: Text('$subDone/$subTotal'),
          ),
        ],
      ),
    );
  }
}

