import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/hero_page_route.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/interactive_bubbles.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _restoreRememberedCredentials();
  }

  Future<void> _restoreRememberedCredentials() async {
    final remembered = await context.read<AuthService>().loadRememberedCredentials();
    if (remembered == null || !mounted) return;
    setState(() {
      _emailController.text = remembered.email;
      _passwordController.text = remembered.password;
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      await auth.login(email, password);
      if (_rememberMe) {
        await auth.saveRememberedCredentials(email, password);
      } else {
        await auth.clearRememberedCredentials();
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        heroPageRoute((_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      HapticFeedback.lightImpact();
      setState(() => _error = e.message);
    } catch (_) {
      // No response at all — offline. The only way to still let this rep
      // in without a server round trip is if these are the exact
      // credentials "Remember me" saved from a prior online login on this
      // device, and that login's token + profile are still cached — see
      // AuthService.loginOffline's doc comment.
      final signedInOffline = await auth.loginOffline(email, password);
      if (signedInOffline) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          heroPageRoute((_) => const HomeScreen()),
        );
        return;
      }
      HapticFeedback.lightImpact();
      if (mounted) setState(() => _error = AppLocalizations.of(context).loginOfflineError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Column(
        children: [
          _LoginHeader(theme: theme),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(offset: Offset(0, (1 - value) * -12), child: child),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(l10n.loginSignInTitle, style: theme.textTheme.titleLarge),
                                const SizedBox(height: AppSpacing.xs),
                                Text(l10n.loginSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: l10n.loginEmailLabel,
                              hintText: 'you@company.com',
                              prefixIcon: const Icon(Icons.mail_outline),
                            ),
                            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.loginEmailRequiredError : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: l10n.loginPasswordLabel,
                              hintText: l10n.loginPasswordHint,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? l10n.loginPasswordRequiredError : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          CheckboxListTile(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            title: Text(l10n.loginRememberMe),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            InlineErrorBanner(message: _error!),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          LoadingButton(
                            label: l10n.loginSignInButton,
                            loading: _loading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.loginAccessNotice,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green curved top bar that echoes the splash screen's palette, so the
/// brand feels continuous as the Hero-tagged icon lands here.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B4A2E), Color(0xFF12744B), Color(0xFF1FAE72)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: InteractiveBubbles(count: 3, minSize: 90, maxSize: 160)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl + AppSpacing.md),
              child: Column(
                children: [
                  Hero(
                    tag: 'app-icon',
                    child: Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: const Image(image: AssetImage('assets/app_icon.png')),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.commonAppName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.loginTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
