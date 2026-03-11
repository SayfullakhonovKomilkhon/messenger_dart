import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _showLoginView = false;

  @override
  void initState() {
    super.initState();
    _rememberMe = LocalStorage.getRememberMe();
    if (_rememberMe) {
      final savedId = LocalStorage.getSavedUserId();
      if (savedId != null) _loginController.text = savedId;
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();
    if (login.isEmpty || password.isEmpty) return;

    if (_rememberMe) {
      LocalStorage.setRememberMe(true);
      LocalStorage.setSavedUserId(login);
    } else {
      LocalStorage.setRememberMe(false);
      LocalStorage.setSavedUserId(null);
    }

    await ref.read(authStateProvider.notifier).login(login, password);
  }

  @override
  Widget build(BuildContext context) {
    return _showLoginView ? _buildLoginView() : _buildWelcomeView();
  }

  Widget _buildWelcomeView() {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const _HeroLetter(),
                const SizedBox(height: 24),
                const _BrandedTitle(),
                const SizedBox(height: 12),
                Text(
                  'Мессенджер с полным шифрованием',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _FeatureItem(
                  icon: Icons.shield_outlined,
                  title: 'Номер телефона не требуется',
                  subtitle: 'Создайте аккаунт без предоставления личных данных',
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.lock_outline,
                  title: 'Сквозное шифрование',
                  subtitle: 'Ваши сообщения зашифрованы и конфиденциальны',
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.public,
                  title: 'Децентрализованная сеть',
                  subtitle: 'Никаких центральных серверов для сбора ваших данных',
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => context.go('/register'),
                    child: const Text(
                      'Создать аккаунт',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showLoginView = true),
                    child: const Text(
                      'У меня есть аккаунт',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Войти',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Введите логин и пароль для входа',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                TextField(
                  controller: _loginController,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: 'Логин',
                    hintText: 'Введите логин',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    hintText: 'Ваш пароль',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: const Text('Запомнить меня'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: authState.isLoading ? null : _login,
                    child: authState.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Вход...', style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : const Text(
                            'Войти',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('или', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showLoginView = false),
                    child: const Text(
                      'Назад',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroLetter extends StatelessWidget {
  const _HeroLetter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: const [
            Color(0xFFFF6B6B),
            Color(0xFFE4AD3C),
            Color(0xFF28A745),
            Color(0xFF3B59FF),
            Color(0xFFFF6B6B),
          ],
          transform: const GradientRotation(-math.pi / 2),
        ),
      ),
      child: Center(
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: const Center(
            child: Text(
              'D',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandedTitle extends StatelessWidget {
  const _BrandedTitle();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: 1,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('D', style: style.copyWith(color: AppColors.brandD.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 1.0 : 1.0))),
        Text('e', style: style.copyWith(color: AppColors.brandE)),
        Text('m', style: style.copyWith(color: AppColors.brandM)),
        Text('o', style: style.copyWith(color: AppColors.brandO)),
        Text('s', style: style.copyWith(color: AppColors.brandS)),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
