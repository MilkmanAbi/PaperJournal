import 'package:flutter/material.dart';
import '../global.dart';
import '../theme/amber_theme.dart';

/// ErrorStatePage — the "Lonely-Cosmos" moment from Amber-Paper §4.2.
/// This is the one deliberate dark screen in an otherwise light/amber
/// app: no-network errors, unknown routes, and "searched for a booking
/// that isn't there anymore" all land here. Per the doc, the WHOLE
/// screen switches to dark tokens for this (wrapped in AmberTheme.dark()
/// below) rather than just dropping a dark image on a light background.
///
/// [message] lets a caller customize the one line of copy (e.g. the
/// booking-not-found case), defaults to the generic empty/error line.
class ErrorStatePage extends StatelessWidget {
  final String message;

  const ErrorStatePage({
    super.key,
    this.message = 'Nothing here yet. The stars are still deciding.',
  });

  @override
  Widget build(BuildContext context) {
    // Theme() override so this screen is always dark, regardless of
    // whatever theme/darkTheme the rest of the app is currently on -
    // that's the "deliberate pause" bit from the doc.
    return Theme(
      data: AmberTheme.dark(),
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: scheme.surface,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AmberSpace.s4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: AmberRadius.boxRadius,
                        child: Image.asset(
                          'assets/wallpapers/Undefined/Lonely-Cosmos.jpg',
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: AmberSpace.s4),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AmberSpace.s4),
                      ElevatedButton(
                        onPressed: () {
                          // same pattern as HomePage's logout - just bail all the way
                          // back to home/login rather than popping, since this page
                          // can itself end up being the first route (bad initial route)
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Global.isLoggedIn ? '/home' : '/login',
                            (route) => false,
                          );
                        },
                        child: const Text('Back to safety'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
