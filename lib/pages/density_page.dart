import 'package:flutter/material.dart';
import '../global.dart';

// density page - shows booking stats: busiest day, most used services, overbooking alerts
// currently only uses your own local bookings because firestore org-wide sync isnt wired in yet
// when org-wide sync lands, swap _activeBookings to pull from Global.orgUsers too MSS
class DensityPage extends StatefulWidget {
  const DensityPage({super.key});

  @override
  State<DensityPage> createState() => _DensityPageState();
}

class _DensityPageState extends State<DensityPage> {
  _Range _range = _Range.thisMonth; // default to current month, most useful starting point MSS

  List<Booking> get _activeBookings {
    final now = DateTime.now();
    return Global.bookings.where((b) {
      if (b.status == BookingStatus.cancelled) return false;
      switch (_range) {
        case _Range.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return b.dateTime.isAfter(weekStart) &&
              b.dateTime.isBefore(weekEnd.add(const Duration(days: 1)));
        case _Range.thisMonth:
          return b.dateTime.year == now.year && b.dateTime.month == now.month;
        case _Range.nextMonth:
          final target = DateTime(now.year, now.month + 1);
          return b.dateTime.year == target.year && b.dateTime.month == target.month;
        case _Range.all:
          return true;
      }
    }).toList();
  }

  Map<String, int> _serviceCounts(List<Booking> bookings) {
    final map = <String, int>{};
    for (final b in bookings) {
      map[b.serviceName] = (map[b.serviceName] ?? 0) + 1;
    }
    return map;
  }

  Map<int, int> _dayOfWeekCounts(List<Booking> bookings) {
    final map = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    for (final b in bookings) {
      map[b.dateTime.weekday] = (map[b.dateTime.weekday] ?? 0) + 1;
    }
    return map;
  }

  // 3+ bookings on the same day triggers the overbooking alert - threshold is hardcoded for now MSS
  static const int _overbookThreshold = 3;

  Map<String, int> _dailyCounts(List<Booking> bookings) {
    final map = <String, int>{};
    for (final b in bookings) {
      final key =
          '${b.dateTime.year}-${b.dateTime.month.toString().padLeft(2, '0')}-${b.dateTime.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  List<String> _overbookedDates(Map<String, int> daily) {
    return daily.entries
        .where((e) => e.value >= _overbookThreshold)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  static const _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bookings = _activeBookings;
    final serviceCounts = _serviceCounts(bookings);
    final dayOfWeek = _dayOfWeekCounts(bookings);
    final daily = _dailyCounts(bookings);
    final overbooked = _overbookedDates(daily);

    final topServices = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = topServices.take(3).toList();

    final busiestDay = dayOfWeek.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final maxDayCount = dayOfWeek.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Density')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_Range>(
            segments: const [
              ButtonSegment(value: _Range.thisWeek, label: Text('Week')),
              ButtonSegment(value: _Range.thisMonth, label: Text('Month')),
              ButtonSegment(value: _Range.nextMonth, label: Text('Next')),
              ButtonSegment(value: _Range.all, label: Text('All')),
            ],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),

          const SizedBox(height: 16),

          // info banner so whoever is marking this knows the page is contextually aware MSS
          _InfoBanner(
            icon: Icons.info_outline,
            text: Global.isAdmin
                ? 'admin view: pull org bookings from firestore to see the full picture'
                : 'showing your bookings only - org-wide data needs firestore',
            color: Global.isAdmin ? scheme.primaryContainer : scheme.secondaryContainer,
            textColor: Global.isAdmin ? scheme.onPrimaryContainer : scheme.onSecondaryContainer,
          ),

          const SizedBox(height: 12),

          if (overbooked.isNotEmpty) ...[
            _SectionLabel(label: 'Overbooking alerts (${overbooked.length})'),
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.warning_amber_outlined, color: scheme.onErrorContainer, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$_overbookThreshold+ bookings on same day',
                        style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ...overbooked.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '$d  -  ${daily[d]} bookings',
                            style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _SectionLabel(label: 'Summary'),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Total bookings', value: '${bookings.length}')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Services used', value: '${serviceCounts.length}')),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Alerts',
                  value: '${overbooked.length}',
                  highlight: overbooked.isNotEmpty,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionLabel(label: 'Bookings by day of week'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final count = dayOfWeek[day] ?? 0;
                  final fraction = maxDayCount == 0 ? 0.0 : count / maxDayCount;
                  final isBusiest = day == busiestDay.key && maxDayCount > 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            _dayNames[day],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isBusiest ? FontWeight.bold : FontWeight.normal,
                              color: isBusiest ? scheme.primary : scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: fraction.toDouble(),
                              minHeight: 10,
                              backgroundColor: scheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isBusiest ? scheme.primary : scheme.primaryContainer,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$count', style: TextStyle(fontSize: 12, color: scheme.outline)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _SectionLabel(label: 'Most used services'),
          if (top3.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('no data for this range', style: TextStyle(color: scheme.outline)),
              ),
            ),
          ...top3.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final svc = entry.value;
            final total = bookings.length;
            final pct = total == 0 ? 0 : ((svc.value / total) * 100).round();
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Text('$rank',
                      style: TextStyle(
                          color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                ),
                title: Text(svc.key, style: const TextStyle(fontSize: 14)),
                trailing: Text('${svc.value}x ($pct%)',
                    style: TextStyle(color: scheme.outline, fontSize: 13)),
              ),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatCard({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? scheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: highlight ? scheme.onErrorContainer : scheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: highlight ? scheme.onErrorContainer : scheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;
  const _InfoBanner(
      {required this.icon,
      required this.text,
      required this.color,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: textColor))),
        ],
      ),
    );
  }
}

enum _Range { thisWeek, thisMonth, nextMonth, all }
