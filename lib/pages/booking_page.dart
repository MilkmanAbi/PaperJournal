import 'package:flutter/material.dart';
import '../global.dart';
import 'error_page.dart';

// booking page - make a booking, look one up by id, see your list
// also gets a pre-fill argument from services page so you dont have to retype the service name MSS
// the search-by-id thing pushes the error page if the booking doesnt exist
// thats the "lonely cosmos" moment from the design brief
class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _serviceController = TextEditingController();
  final _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // services page passes the service name as a route arg and we stuff it into the text field MSS
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

  // showDatePicker is async - it suspends until the user picks a date and closes the dialog MSS
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

  // booking id not found - push to the lonely cosmos error page, thats the intended empty state MSS
  void _searchBooking() {
    final id = _searchController.text.trim();
    if (id.isEmpty) return;

    final found = Global.findBooking(id);
    if (found == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ErrorStatePage(
            message: "that booking is gone - deleted or the id is wrong",
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
            decoration: const InputDecoration(labelText: 'what are you booking?'),
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
                  decoration: const InputDecoration(labelText: 'booking ID'),
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
              // cancelled = show trash to actually delete it
              // non-cancelled booking gets an X button to cancel it MSS
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
