import 'package:flutter/material.dart';
import '../global.dart';
import 'error_page.dart';

/// BookingPage — owns its own "make a booking" form state. The only
/// thing that leaves this page is a Booking object handed to
/// Global.addBooking(). It's a tab in AppShell now rather than being
/// pushed from HomePage, and AppShell rebuilds tabs fresh on every
/// switch (see app_shell.dart) so CalendarHomePage picks up new
/// bookings without needing a manual refresh callback.
class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _serviceController = TextEditingController();
  final _searchController = TextEditingController(); // booking-ID lookup, see _searchBooking()
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ServicesPage passes the service name as a route argument - pre-fill it
    final prefill = ModalRoute.of(context)?.settings.arguments as String?;
    if (prefill != null && _serviceController.text.isEmpty) {
      _serviceController.text = prefill;
    }
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // showDatePicker is one of the few built-in Flutter widgets that's
  // only available as async — it has to wait for the user to close the
  // calendar dialog, so Flutter itself requires async/await here.
  // Everything else in this file is plain, synchronous code.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _confirmBooking() {
    if (_serviceController.text.trim().isEmpty) return;

    setState(() {
      Global.addBooking(
        Booking(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          serviceName: _serviceController.text.trim(),
          dateTime: _selectedDate,
        ),
      );
      _serviceController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booked')),
    );
  }

  // looks up a booking by its id. if it's gone (deleted, or just a
  // bad/old id) this is the "deleted booking searched for" case from
  // the Amber-Paper doc, so it pushes the Lonely-Cosmos error page
  // instead of just doing nothing.
  void _searchBooking() {
    final id = _searchController.text.trim();
    if (id.isEmpty) return;

    final found = Global.findBooking(id);
    if (found == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ErrorStatePage(
            message: "That booking's gone - maybe it was deleted, or the ID's off.",
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${found.serviceName} · ${found.status.name}')),
    );
  }

  void _deleteBooking(String id) {
    setState(() => Global.deleteBooking(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _serviceController,
            decoration: const InputDecoration(labelText: 'What are you booking?'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _confirmBooking, child: const Text('Confirm booking')),
          const Divider(height: 32),
          Text('Look up a booking', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(labelText: 'Booking ID'),
                  onSubmitted: (_) => _searchBooking(),
                ),
              ),
              IconButton(icon: const Icon(Icons.search), onPressed: _searchBooking),
            ],
          ),
          const Divider(height: 32),
          Text('Your bookings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...Global.bookings.map(
            (b) => ListTile(
              title: Text(b.serviceName),
              subtitle: Text('${b.id} · ${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year} · ${b.status.name}'),
              // cancelled bookings get a delete (trash) action instead of
              // cancel - that's the only way a booking actually leaves the
              // list now, everything else just changes status
              trailing: b.status == BookingStatus.cancelled
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteBooking(b.id),
                    )
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => Global.cancelBooking(b.id)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}