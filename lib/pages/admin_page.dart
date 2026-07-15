import 'package:flutter/material.dart';
import '../global.dart';
import '../services/firebase_service.dart';

// AdminPage - only visible when Global.isAdmin is true (set on login with admin@example.com / ADMIN-PASSWORD).
// normal users never see this tab, it doesn't even exist in their AppShell.
// Shows all users from public Firestore - anyone who has ever signed up appears here,
// even if they never filled in their profile. AAS
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<OrgUser> get _users => Global.orgUsers;
  List<ConflictInfo> get _conflicts => _findConflicts();
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // auto-load users when admin page opens
    _refreshUsers();
  }

  List<ConflictInfo> _findConflicts() {
    final conflicts = <ConflictInfo>[];
    final allBookings = <_UserBooking>[];
    for (final user in _users) {
      for (final b in user.bookings) {
        allBookings.add(_UserBooking(user: user, booking: b));
      }
    }

    for (var i = 0; i < allBookings.length; i++) {
      for (var j = i + 1; j < allBookings.length; j++) {
        final a = allBookings[i];
        final b = allBookings[j];
        if (_isSameDay(a.booking.dateTime, b.booking.dateTime) &&
            a.booking.serviceName == b.booking.serviceName &&
            a.booking.status != BookingStatus.cancelled &&
            b.booking.status != BookingStatus.cancelled) {
          conflicts.add(ConflictInfo(a: a, b: b));
        }
      }
    }
    return conflicts;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _refreshUsers() async {
    setState(() { _loading = true; _loadError = null; });

    // Try public DB first (shows ALL signed-up users)
    final err = await FB.fetchAllPublicUsers();

    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadError = err;
    });

    if (err != null) {
      // fallback: try private db mirror
      final privateErr = await FB.fetchOrgUsers();
      if (mounted) {
        setState(() {
          _loadError = privateErr ?? null;
        });
        if (privateErr == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded ${Global.orgUsers.length} users (from private db fallback)')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final conflicts = _conflicts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh users',
              onPressed: _refreshUsers,
            ),
        ],
      ),
      body: _loading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // error banner
                if (_loadError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_loadError!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // conflicts banner
                if (conflicts.isNotEmpty) ...[
                  Card(
                    color: scheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_outlined, color: scheme.onErrorContainer),
                              const SizedBox(width: 8),
                              Text(
                                '${conflicts.length} conflict${conflicts.length > 1 ? 's' : ''} found',
                                style: TextStyle(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...conflicts.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${c.a.user.name} and ${c.b.user.name} both booked '
                                  '"${c.a.booking.serviceName}" on '
                                  '${c.a.booking.dateTime.day}/${c.a.booking.dateTime.month}',
                                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // no conflicts
                if (conflicts.isEmpty && _users.isNotEmpty) ...[
                  Card(
                    color: scheme.secondaryContainer,
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.check_circle_outline, color: scheme.onSecondaryContainer),
                      title: Text('No booking conflicts', style: TextStyle(color: scheme.onSecondaryContainer)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // stats row
                if (_users.isNotEmpty) ...[
                  Row(
                    children: [
                      _StatChip(
                        label: 'USERS',
                        value: '${_users.length}',
                        icon: Icons.group_outlined,
                        scheme: scheme,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'BOOKINGS',
                        value: '${_users.fold(0, (s, u) => s + u.bookings.length)}',
                        icon: Icons.event_available_outlined,
                        scheme: scheme,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'CONFLICTS',
                        value: '${conflicts.length}',
                        icon: Icons.warning_amber_outlined,
                        scheme: scheme,
                        highlight: conflicts.isNotEmpty,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // user list header
                Text('All Users (${_users.length})', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                if (_users.isEmpty && !_loading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.group_outlined, size: 48, color: scheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'No users yet.\nNew sign-ups will appear here automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ),

                ..._users.map((user) => _UserCard(user: user)),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme scheme;
  final bool highlight;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.scheme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final fg = highlight ? scheme.onErrorContainer : scheme.onSurface;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: fg.withValues(alpha: 0.6)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fg)),
            Text(label, style: TextStyle(fontSize: 9, letterSpacing: 1, color: fg.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final OrgUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeBookings = user.bookings.where((b) => b.status != BookingStatus.cancelled).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: TextStyle(fontSize: 11, color: scheme.outline)),
            if (user.companyName != null)
              Text('${user.companyName}${user.companyRole != null ? ' · ${user.companyRole}' : ''}',
                style: TextStyle(fontSize: 11, color: scheme.primary)),
          ],
        ),
        trailing: activeBookings > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$activeBookings booking${activeBookings > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 10, color: scheme.onPrimaryContainer)),
              )
            : null,
        children: [
          // profile details row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.companyCode != null)
                  _InfoRow(icon: Icons.tag, text: 'Org code: ${user.companyCode}', scheme: scheme),
                if (user.bookings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text('No bookings', style: TextStyle(fontStyle: FontStyle.italic, color: scheme.outline, fontSize: 12)),
                  ),
              ],
            ),
          ),
          ...user.bookings.map(
            (b) => ListTile(
              dense: true,
              leading: Icon(
                b.status == BookingStatus.cancelled
                    ? Icons.cancel_outlined
                    : b.status == BookingStatus.confirmed
                        ? Icons.check_circle_outline
                        : Icons.schedule,
                size: 16,
                color: b.status == BookingStatus.cancelled
                    ? scheme.error
                    : b.status == BookingStatus.confirmed
                        ? Colors.green
                        : scheme.outline,
              ),
              title: Text(b.serviceName, style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                '${b.dateTime.day}/${b.dateTime.month}/${b.dateTime.year}  ·  ${b.status.name}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme scheme;
  const _InfoRow({required this.icon, required this.text, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: scheme.outline),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: scheme.outline)),
        ],
      ),
    );
  }
}

class _UserBooking {
  final OrgUser user;
  final Booking booking;
  const _UserBooking({required this.user, required this.booking});
}

class ConflictInfo {
  final _UserBooking a;
  final _UserBooking b;
  const ConflictInfo({required this.a, required this.b});
}