import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/api_client_provider.dart';
import '../../../providers/auth_providers.dart';
import 'auth_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final dio = ref.read(apiClientProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    Future<Response<Map<String, dynamic>>> doRequest() => dio.post<Map<String, dynamic>>(
          Endpoints.authLogin,
          data: {'email': email, 'password': password},
        );

    try {
      Response<Map<String, dynamic>> resp;
      try {
        resp = await doRequest();
      } on DioException catch (e) {
        final isRetryable = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        if (isRetryable && mounted) {
          await Future<void>.delayed(const Duration(seconds: 3));
          if (!mounted) return;
          resp = await doRequest();
        } else {
          rethrow;
        }
      }

      final token = resp.data?['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Missing token');
      }

      ref.read(authTokenProvider.notifier).state = token;
      await AppStorage.saveToken(token);

      if (mounted) {
        context.replace('/');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessageFromDioException(e)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong while signing in.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: AppColors.splashGradient),
          ),
          // Soft blur circles for depth
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo + headline
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.champagneGlasses,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn()
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOut),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 80.ms).slideY(begin: -0.15, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to discover events worldwide',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 120.ms).slideY(begin: -0.1, end: 0),
                    const SizedBox(height: 32),
                    // Card
                    AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: Colors.grey.shade900, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                prefixIcon: Icon(FontAwesomeIcons.envelope, size: 20, color: primary.withValues(alpha: 0.8)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: primary, width: 1),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Email is required';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.06, end: 0, curve: Curves.easeOut),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _passwordController,
                              style: TextStyle(color: Colors.grey.shade900, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••••',
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                prefixIcon: Icon(FontAwesomeIcons.lock, size: 20, color: primary.withValues(alpha: 0.8)),
                                suffixIcon: IconButton(
                                  icon: FaIcon(
                                    _obscurePassword ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: primary, width: 1),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if ((value ?? '').isEmpty) return 'Password is required';
                                return null;
                              },
                            ).animate().fadeIn(delay: 260.ms).slideX(begin: 0.06, end: 0, curve: Curves.easeOut),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: const Text('Forgot password?'),
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Sign In'),
                            ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'or continue with',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                              ],
                            ).animate().fadeIn(delay: 400.ms),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.go('/'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      foregroundColor: Colors.grey.shade800,
                                    ),
                                    icon: const FaIcon(FontAwesomeIcons.google, size: 20, color: Color(0xFF4285F4)),
                                    label: const Text('Google'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.go('/'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      foregroundColor: Colors.grey.shade800,
                                    ),
                                    icon: const FaIcon(FontAwesomeIcons.apple, size: 20, color: Color(0xFF000000)),
                                    label: const Text('Apple'),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 440.ms).slideY(begin: 0.04, end: 0),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/register'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                  ),
                                  child: const Text('Sign up'),
                                ),
                              ],
                            ).animate().fadeIn(delay: 520.ms),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 160.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

