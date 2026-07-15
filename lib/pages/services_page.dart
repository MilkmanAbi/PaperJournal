import 'package:flutter/material.dart';

// ServicesPage - browse what's bookable before hitting the booking form.
// hardcoded list for now, swap with a Firestore collection later.
// tapping a service navigates to BookingPage with the name pre-filled
// so you don't have to type it manually.
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  // TODO(firebase): pull this from Firestore collection 'services'
  // for now it's hardcoded - enough to demo the flow
  static const List<ServiceItem> _allServices = [
    ServiceItem(
      id: 'svc_001',
      name: 'General Consultation',
      category: 'Consultation',
      description: 'One-on-one session with a staff member to discuss any queries or concerns.',
      durationMins: 30,
      icon: Icons.person_outline,
    ),
    ServiceItem(
      id: 'svc_002',
      name: 'Room Booking - Meeting Room A',
      category: 'Room',
      description: 'Small meeting room, seats up to 6. Projector and whiteboard included.',
      durationMins: 60,
      icon: Icons.meeting_room_outlined,
    ),
    ServiceItem(
      id: 'svc_003',
      name: 'Room Booking - Conference Hall',
      category: 'Room',
      description: 'Large conference hall, seats up to 40. AV setup available on request.',
      durationMins: 120,
      icon: Icons.meeting_room_outlined,
    ),
    ServiceItem(
      id: 'svc_004',
      name: 'Equipment Loan',
      category: 'Equipment',
      description: 'Borrow equipment for a day. Check availability before booking.',
      durationMins: 480,
      icon: Icons.build_outlined,
    ),
    ServiceItem(
      id: 'svc_005',
      name: 'Workshop Session',
      category: 'Workshop',
      description: 'Hands-on group workshop. Limited slots per session.',
      durationMins: 90,
      icon: Icons.groups_outlined,
    ),
    ServiceItem(
      id: 'svc_006',
      name: 'IT Support',
      category: 'Consultation',
      description: 'Get help with device or software issues from the IT desk.',
      durationMins: 45,
      icon: Icons.computer_outlined,
    ),
    ServiceItem(
      id: 'svc_007',
      name: 'Lab Access',
      category: 'Equipment',
      description: 'Book a slot for supervised lab access. Bring your own materials.',
      durationMins: 60,
      icon: Icons.science_outlined,
    ),
  ];

  List<String> get _categories {
    final cats = _allServices.map((s) => s.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<ServiceItem> get _filtered {
    return _allServices.where((s) {
      final matchesSearch = _query.isEmpty ||
          s.name.toLowerCase().contains(_query.toLowerCase()) ||
          s.description.toLowerCase().contains(_query.toLowerCase());
      final matchesCat = _selectedCategory == null || s.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  void _bookThis(ServiceItem service) {
    // push to BookingPage with the service name pre-filled
    // BookingPage reads the route argument and stuffs it into the text field
    Navigator.pushNamed(context, '/booking', arguments: service.name);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: Column(
        children: [
          // search + filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // category chips
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                ..._categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(
                        () => _selectedCategory = _selectedCategory == cat ? null : cat,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // service list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: scheme.outline),
                        const SizedBox(height: 8),
                        Text('No services match', style: TextStyle(color: scheme.outline)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final svc = filtered[i];
                      return _ServiceCard(service: svc, onBook: () => _bookThis(svc));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback onBook;

  const _ServiceCard({required this.service, required this.onBook});

  String _durationLabel(int mins) {
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(service.icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    service.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // category chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          service.category,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSecondaryContainer),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule, size: 12, color: scheme.outline),
                      const SizedBox(width: 2),
                      Text(
                        _durationLabel(service.durationMins),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.outline),
                      ),
                      const Spacer(),
                      // book button
                      FilledButton.tonal(
                        onPressed: onBook,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Book'),
                      ),
                    ],
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

// plain data class - no state, no methods needed beyond this
class ServiceItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final int durationMins;
  final IconData icon;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.durationMins,
    required this.icon,
  });
}
