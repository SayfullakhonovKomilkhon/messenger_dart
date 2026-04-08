import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/bot_provider.dart';
import '../../l10n/app_localizations.dart';

class CreateBotScreen extends ConsumerStatefulWidget {
  const CreateBotScreen({super.key});

  @override
  ConsumerState<CreateBotScreen> createState() => _CreateBotScreenState();
}

class _CreateBotScreenState extends ConsumerState<CreateBotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _descCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final bot = await ref.read(myBotsProvider.notifier).create(
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        avatarUrl: _avatarCtrl.text.trim(),
      );
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.botCreated)),
      );
      context.pop();
      context.push('/settings/bots/${bot.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.createBot),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l.botName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l.botNameRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  labelText: l.botUsername,
                  border: const OutlineInputBorder(),
                  prefixText: '@',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l.botUsernameRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: l.botDescription,
                  hintText: l.botDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 256,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avatarCtrl,
                decoration: InputDecoration(
                  labelText: l.botAvatar,
                  hintText: 'https://...',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.create, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
