import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class BlockedContactsScreen extends ConsumerStatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  ConsumerState<BlockedContactsScreen> createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends ConsumerState<BlockedContactsScreen> {
  List<Map<String, dynamic>> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient().dio.get('/users/me/blocked');
      final list = res.data is List ? (res.data as List) : [];
      setState(() {
        _blocked = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Разблокировать'),
        content: Text('Разблокировать $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Разблокировать'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient().dio.delete('/users/$userId/block');
      setState(() {
        _blocked.removeWhere((b) => b['id'] == userId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Контакт разблокирован')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заблокированные контакты'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Нет заблокированных контактов',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Заблокированные вами контакты\nпоявятся здесь',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _blocked.length,
                  itemBuilder: (context, index) {
                    final user = _blocked[index];
                    final name = user['name'] as String? ?? 'Неизвестный';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          backgroundImage: user['avatarUrl'] != null
                              ? NetworkImage(user['avatarUrl'])
                              : null,
                          child: user['avatarUrl'] == null
                              ? Text(name[0].toUpperCase(),
                                  style: TextStyle(color: Colors.red.shade700))
                              : null,
                        ),
                        title: Text(name),
                        subtitle: user['id'] != null
                            ? Text(
                                (user['id'] as String).length > 16
                                    ? '${(user['id'] as String).substring(0, 16)}...'
                                    : user['id'] as String,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              )
                            : null,
                        trailing: OutlinedButton(
                          onPressed: () => _unblock(user['id'] as String, name),
                          child: const Text('Разблокировать'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
