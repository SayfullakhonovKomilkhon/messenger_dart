import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';

class NewChatDialog extends ConsumerStatefulWidget {
  const NewChatDialog({super.key});

  @override
  ConsumerState<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<NewChatDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/users/search', queryParameters: {'query': query});
      setState(() {
        _results = (res.data as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _createConversation(String participantId, String name, String? avatar) async {
    try {
      final res = await ApiClient().dio.post('/conversations', data: {
        'participantId': participantId,
      });
      final convId = res.data['id'] as String;
      ref.read(conversationsProvider.notifier).load();
      if (mounted) {
        Navigator.pop(context);
        context.push(
          '/conversation/$convId?name=${Uri.encodeComponent(name)}'
          '&participantId=$participantId'
          '${avatar != null ? '&avatar=${Uri.encodeComponent(avatar)}' : ''}',
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Chat'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                      child: user['avatarUrl'] == null
                          ? Text((user['name'] as String).isNotEmpty
                              ? (user['name'] as String)[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    title: Text(user['name'] as String),
                    subtitle: user['username'] != null
                        ? Text('@${user['username']}')
                        : null,
                    trailing: user['isOnline'] == true
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () => _createConversation(
                      user['id'] as String,
                      user['name'] as String,
                      user['avatarUrl'] as String?,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
