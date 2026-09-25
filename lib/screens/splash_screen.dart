import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/animated_bubbles.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Shown once at cold start. Resolves the session, then swaps its own body
/// for Home or Login in place — no Navigator push. Pushing a real route here
/// would force Flutter to build and lay out the entire destination screen in
/// one frame just to compute where its `Hero(tag: 'app-icon', ...)` badge
/// sits, which is what caused the hitch right at hand-off; an in-place
/// crossfade skips that Hero-flight computation entirely. Login/Home keep
/// their own Hero badges for the transitions *between* them, which stay
/// normal Navigator pushes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showBrand = false;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    // Staggered slightly behind the icon so it reads as a deliberate reveal,
    // not everything landing on screen at once.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _showBrand = true);
    });
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthService>();
    // A fixed 3s hold so the bubble animation is clearly seen before
    // handing off, even when the session check resolves near-instantly.
    try {
      await Future.wait([
        auth.restoreSession(),
        Future.delayed(const Duration(seconds: 3)),
      ]).timeout(const Duration(seconds: 20));
    } catch (_) {
      // restoreSession() already swallows its own network errors, so this
      // only fires for something unexpected (e.g. SharedPreferences itself
      // failing) — fall through to the login screen rather than leaving the
      // splash screen stuck forever.
    }
    if (!mounted) return;
    setState(() {
      _destination = auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _destination ?? _SplashBody(key: const ValueKey('splash'), showBrand: _showBrand),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody({super.key, required this.showBrand});

  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B4A2E), Color(0xFF12744B), Color(0xFF1FAE72)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedBubbles(count: 3, minSize: 220, maxSize: 340),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 28, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: const Image(image: AssetImage('assets/app_icon.png')),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedSlide(
                    offset: showBrand ? Offset.zero : const Offset(0, 0.4),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: showBrand ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: Text(
                        l10n.splashCompanyName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 56,
              left: 0,
              right: 0,
              child: Text(
                l10n.commonAppName,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
