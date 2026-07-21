import 'package:flutter/material.dart';
import '../global.dart';
import 'calendar_home_page.dart';
import 'services_page.dart';
import 'booking_page.dart';
import 'community_page.dart';
import 'density_page.dart';
import 'profile_page.dart';
import 'admin_page.dart';

// AppShell - bottom bar + page switcher.
// admin sees ONLY Admin + Profile, two tabs, nothing else
// normal users get Home | Services | Bookings | Community | Density | Profile
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  Widget _currentPage() {
    if (Global.isAdmin) {
      // admin shell is just two tabs: Admin (0) and Profile (1)
      switch (_index) {
        case 1: return const ProfilePage();
        case 0:
        default: return const AdminPage();
      }
    }

    // normal user tab order
    switch (_index) {
      case 1: return const ServicesPage();
      case 2: return const BookingPage();
      case 3: return const CommunityPage();
      case 4: return const DensityPage();
      case 5: return const ProfilePage();
      case 0:
      default: return const CalendarHomePage();
    }
  }

  int get _upcomingCount {
    final now = DateTime.now();
    return Global.bookings
        .where((b) => b.status != BookingStatus.cancelled && b.dateTime.isAfter(now))
        .length;
  }

  List<NavigationDestination> get _destinations {
    if (Global.isAdmin) {
      return const [
        NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }
    return const [
      NavigationDestination(icon: Icon(Icons.calendar_month_outlined),   selectedIcon: Icon(Icons.calendar_month),   label: 'Home'),
      NavigationDestination(icon: Icon(Icons.grid_view_outlined),        selectedIcon: Icon(Icons.grid_view),        label: 'Services'),
      NavigationDestination(icon: Icon(Icons.event_available_outlined),  selectedIcon: Icon(Icons.event_available),  label: 'Bookings'),
      NavigationDestination(icon: Icon(Icons.forum_outlined),            selectedIcon: Icon(Icons.forum),            label: 'Community'),
      NavigationDestination(icon: Icon(Icons.bar_chart_outlined),        selectedIcon: Icon(Icons.bar_chart),        label: 'Density'),
      NavigationDestination(icon: Icon(Icons.person_outline),            selectedIcon: Icon(Icons.person),           label: 'Profile'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcomingCount;

    return Scaffold(
      appBar: (!Global.isAdmin && _index == 0)
          ? AppBar(
              title: const Text('PaperJournal'),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    if (upcoming > 0)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            )
          : null,
      body: _currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
