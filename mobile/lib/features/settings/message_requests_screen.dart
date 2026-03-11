import 'package:flutter/material.dart';

class _MessageRequest {
  final String id;
  final String initial;
  final Color avatarColor;
  final String name;
  final String message;

  const _MessageRequest({
    required this.id,
    required this.initial,
    required this.avatarColor,
    required this.name,
    required this.message,
  });
}

class MessageRequestsScreen extends StatefulWidget {
  const MessageRequestsScreen({super.key});

  @override
  State<MessageRequestsScreen> createState() => _MessageRequestsScreenState();
}

class _MessageRequestsScreenState extends State<MessageRequestsScreen> {
  late List<_MessageRequest> _requests;
  late GlobalKey<AnimatedListState> _listKey;

  static const _demoRequests = [
    _MessageRequest(
      id: '1',
      initial: 'И',
      avatarColor: Colors.purple,
      name: 'Иван Иванов',
      message: 'Привет, нашел твой ID на форуме. Не против пообщаться?',
    ),
    _MessageRequest(
      id: '2',
      initial: 'М',
      avatarColor: Colors.orange,
      name: 'Мария Гасиева',
      message: 'Привет! Мы виделись на митапе на прошлой неделе 👋',
    ),
    _MessageRequest(
      id: '3',
      initial: 'Н',
      avatarColor: Colors.red,
      name: 'Неизвестный',
      message: 'Посмотрите на эту потрясающую возможность...',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _requests = List.from(_demoRequests);
    _listKey = GlobalKey<AnimatedListState>();
  }

  void _removeRequest(int index, _MessageRequest request) {
    final removedIndex = index;
    setState(() {
      _requests.removeAt(removedIndex);
    });
    _listKey.currentState?.removeItem(
      removedIndex,
      (context, animation) => _buildRequestItem(context, request, animation, true),
    );
  }

  void _onAccept(int index) {
    final request = _requests[index];
    _removeRequest(index, request);
  }

  void _onDecline(int index) {
    final request = _requests[index];
    _removeRequest(index, request);
  }

  void _onClearAll() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все'),
        content: const Text(
          'Вы уверены, что хотите удалить все запросы сообщений?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() => _requests.clear());
      }
    });
  }

  Widget _buildRequestItem(
    BuildContext context,
    _MessageRequest request,
    Animation<double> animation,
    bool isRemoving,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: request.avatarColor,
                  child: Text(
                    request.initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.message,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      if (!isRemoving) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _onAccept(_requests.indexOf(request)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Принять'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _onDecline(_requests.indexOf(request)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text('Отклонить'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запросы сообщений'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Запросов нет',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Запросы от новых контактов появятся здесь',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: _requests.length,
                    itemBuilder: (context, index, animation) {
                      final request = _requests[index];
                      return _buildRequestItem(context, request, animation, false);
                    },
                  ),
          ),
          if (_requests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _onClearAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Очистить все'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
