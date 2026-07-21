import 'package:flutter/material.dart';
import '../global.dart';

// notifications page - derived from Global.bookings, no extra storage needed
// okay this just filters a list and sorts it. dude. PSV
// shows upcoming non-cancelled bookings sorted nearest first - why tf would you want past ones PSV
// urgency colors: red = less than a day, orange = less than 3 days, normal otherwise
// bruh this is traffic lights. for a calendar. PSV
// in prod this would pair with FCM push, for now its just an in-app list
// okay, future problem. dude. PSV
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  List<_Reminder> _buildReminders() {
    final now = DateTime.now();
    final upcoming = Global.bookings
        .where((b) => b.status != BookingStatus.cancelled && b.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return upcoming.map((b) {
      final diff = b.dateTime.difference(now);
      return _Reminder(booking: b, diff: diff);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reminders = _buildReminders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (reminders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text('${reminders.length} upcoming'),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text("you're all clear", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('no upcoming bookings', style: TextStyle(color: scheme.outline)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ReminderCard(reminder: reminders[i]),
            ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final _Reminder reminder;
  const _ReminderCard({required this.reminder});

  String _timeLabel(Duration diff) {
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'In ${diff.inHours}h';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return 'In ${diff.inDays} days';
    return 'In ${(diff.inDays / 7).floor()} week${diff.inDays >= 14 ? 's' : ''}';
  }

  Color _urgencyColor(BuildContext context, Duration diff) {
    final scheme = Theme.of(context).colorScheme;
    if (diff.inHours < 24) return scheme.error;
    if (diff.inDays < 3) return Colors.orange;
    return scheme.primary;
  }

  IconData _urgencyIcon(Duration diff) {
    if (diff.inHours < 24) return Icons.alarm;
    if (diff.inDays < 3) return Icons.notifications_active_outlined;
    return Icons.event_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final b = reminder.booking;
    final diff = reminder.diff;
    final urgency = _urgencyColor(context, diff);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: urgency.withValues(alpha: 0.12),
          child: Icon(_urgencyIcon(diff), color: urgency),
        ),
        title: Text(b.serviceName),
        subtitle: Text(
          '${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year}  -  ${b.status.name}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _timeLabel(diff),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: urgency, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${b.id.substring(b.id.length > 6 ? b.id.length - 6 : 0)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reminder {
  final Booking booking;
  final Duration diff;
  const _Reminder({required this.booking, required this.diff});
}
