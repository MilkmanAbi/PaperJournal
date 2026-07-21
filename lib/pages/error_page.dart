import 'package:flutter/material.dart';
import '../global.dart';
import '../theme/amber_theme.dart';

// error / lonely cosmos page - the one intentionally dark screen
// bruh why tf is the error page the coolest looking one PSV
// shows when: bad route, booking not found, or anything else that goes wrong
// basically the catch-all of the catch-alls PSV
// whole screen switches to dark theme regardless of system setting
// thats the deliberate pause thing from the design brief. okay, it forces dark mode. dude. PSV
class ErrorStatePage extends StatelessWidget {
  final String message;

  const ErrorStatePage({
    super.key,
    this.message = 'nothing here yet, the stars are still deciding',
  });

  @override
  Widget build(BuildContext context) {
    // Theme() override forces dark for this screen only - yeah that is what it does PSV
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
                          // bail back to home or login depending on session state. bruh this is just a ternary. PSV
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
