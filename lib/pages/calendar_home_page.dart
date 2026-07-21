import 'package:flutter/material.dart';
import '../global.dart';
import '../theme/amber_theme.dart';

// calendar home page - tap a day, see whats on it, add notes
// booking stuff got moved to its own tab so this page only worries about the calendar grid
// separation of concerns, okay, this just draws a calendar. dude. PSV
// month nav is arrow buttons left/right, same pattern as the reference app
class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  // sunday first to match the reference screenshot - no idea why the ref is sunday-first but okay PSV
  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _changeMonth(int delta) {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta));
  }

  int _daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

  // how many blank cells before day 1 - sunday-first grid so monday needs 1 blank etc
  // bruh why tf do calendars use such stupid indexing PSV
  int _leadingBlanks(DateTime month) => DateTime(month.year, month.month, 1).weekday % 7;

  void _addNote() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "what's up..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              setState(() {
                Global.addNote(Note(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  date: _selectedDay,
                  text: text,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leadingBlanks = _leadingBlanks(_focusedMonth);
    final daysInMonth = _daysInMonth(_focusedMonth);
    final today = DateTime.now();
    final monthLabel = '${_focusedMonth.month}/${_focusedMonth.year}';

    return Scaffold(
      appBar: AppBar(title: Text('Hi, ${Global.userName ?? 'there'}')),
      body: ListView(
        padding: const EdgeInsets.all(AmberSpace.s3),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
              Text(monthLabel, style: Theme.of(context).textTheme.titleMedium),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
            ],
          ),

          Row(
            children: _weekdayLabels
                .map((d) => Expanded(
                      child: Center(child: Text(d, style: Theme.of(context).textTheme.labelSmall)),
                    ))
                .toList(),
          ),

          const SizedBox(height: AmberSpace.s2),

          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
              for (int day = 1; day <= daysInMonth; day++)
                _buildDayCell(context, day, scheme, today),
            ],
          ),

          const Divider(height: AmberSpace.s5),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _addNote,
                icon: const Icon(Icons.add),
                label: const Text('Add note'),
              ),
            ],
          ),

          const SizedBox(height: AmberSpace.s2),

          ..._buildSelectedDayContent(context),
        ],
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, int day, ColorScheme scheme, DateTime today) {
    final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final selected = cellDate.year == _selectedDay.year &&
        cellDate.month == _selectedDay.month &&
        cellDate.day == _selectedDay.day;
    final isToday = cellDate.year == today.year &&
        cellDate.month == today.month &&
        cellDate.day == today.day;
    final hasNote = Global.notesForDay(cellDate).isNotEmpty;
    final hasBooking = Global.bookingsForDay(cellDate).isNotEmpty;

    return InkWell(
      onTap: () => setState(() => _selectedDay = cellDate),
      borderRadius: AmberRadius.boxRadius,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : (isToday ? scheme.surfaceContainerHighest : null),
          borderRadius: AmberRadius.boxRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasNote || hasBooking)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasBooking) _dot(AmberColors.dustyBlue), // blue dot = has a booking PSV
                    if (hasNote) _dot(AmberColors.dustyPlum),    // plum = has a note
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 5,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  List<Widget> _buildSelectedDayContent(BuildContext context) {
    final dayNotes = Global.notesForDay(_selectedDay);
    final dayBookings = Global.bookingsForDay(_selectedDay);

    if (dayNotes.isEmpty && dayBookings.isEmpty) {
      return [
        Text('nothing pinned to this day yet', style: Theme.of(context).textTheme.bodySmall),
      ];
    }

    return [
      ...dayBookings.map(
        (b) => Card(
          child: ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: Text(b.serviceName),
            subtitle: Text(b.status.name),
          ),
        ),
      ),
      ...dayNotes.map(
        (n) => Card(
          child: ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text(n.text),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => Global.deleteNote(n.id)),
            ),
          ),
        ),
      ),
    ];
  }
}
