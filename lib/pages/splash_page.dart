import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// splash page - shown during startup while firebase and local storage init saad
// animates a thin progress bar over ~1.8s (dunno, just felt like it) then navigates to home or login
/// wtf bruh, fake loading bar is evil dawg -habibi
// destination is passed in from main() based on whether a session exists
class SplashPage extends StatefulWidget {
  final String destination;
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

    // full bleed splash - hide the status bar for the duration MSS
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut);
    _barCtrl.forward();

    Timer(const Duration(milliseconds: 2100), () {
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
    const accent = Color(0xFF3D6FE0);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/AppIcon/PaperJournal.png',
              width: 96,
              height: 96,
              errorBuilder: (_, __, ___) =>
                  // fallback icon if the asset file isnt present yet MSS
                  const Icon(Icons.book_outlined, size: 72, color: accent),
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

            SizedBox(
              width: 160,
              child: AnimatedBuilder(
                animation: _barAnim,
                builder: (_, __) => LinearProgressIndicator(
                  value: _barAnim.value,
                  backgroundColor: fg.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 12),

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
