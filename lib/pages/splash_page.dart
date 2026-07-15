import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// SplashPage - shown at cold start while the app does its thing (loads session,
// fetches firebase state, whatever). dead simple: logo + linear progress bar.
// auto-navigates to /home or /login once ready, caller passes the destination.
class SplashPage extends StatefulWidget {
  final String destination; // '/home' or '/login'
  const SplashPage({super.key, required this.destination});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();

    // hide the status bar for a full-bleed splash feel
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // animate the progress bar over ~1.8s then navigate
    // in prod this would be tied to actual firebase init completion,
    // but a fixed duration is fine for the skeleton
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut);
    _barCtrl.forward();

    Timer(const Duration(milliseconds: 2100), () {
      // restore system ui before leaving the splash
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (mounted) {
        Navigator.pushReplacementNamed(context, widget.destination);
      }
    });
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF10131C) : const Color(0xFFFFFFFF);
    final fg = isDark ? const Color(0xFFEDEFF5) : const Color(0xFF141924);
    final accent = const Color(0xFF3D6FE0);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // app icon - pull from assets (updated to PaperJournal icon)
            Image.asset(
              'assets/AppIcon/PaperJournal.png',
              width: 96,
              height: 96,
              errorBuilder: (_, __, ___) =>
                  // fallback if asset isn't there yet
                  Icon(Icons.book_outlined, size: 72, color: accent),
            ),
            const SizedBox(height: 24),
            Text(
              'PaperJournal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            // thin progress bar, constrained width so it doesn't go full screen
            SizedBox(
              width: 160,
              child: AnimatedBuilder(
                animation: _barAnim,
                builder: (_, __) => LinearProgressIndicator(
                  value: _barAnim.value,
                  backgroundColor: fg.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // TODO(firebase): swap this string for actual status messages
            // e.g. "Checking connection...", "Loading your data..." etc
            Text(
              'Loading...',
              style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
