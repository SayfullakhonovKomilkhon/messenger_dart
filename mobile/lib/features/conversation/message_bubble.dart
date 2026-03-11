import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../core/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isDeleted) {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (isMine ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest)
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Сообщение удалено',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final bgColor = isMine
        ? theme.colorScheme.primary.withValues(alpha: 0.85)
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMine ? Colors.white : theme.colorScheme.onSurface;

    String timeStr = '';
    try {
      final dt = DateTime.parse(message.createdAt);
      timeStr = DateFormat.Hm().format(dt);
    } catch (_) {}

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.forwardedFromId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forward, size: 12, color: textColor.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text('Переслано',
                        style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: textColor.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            if (message.replyToId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: isMine ? Colors.white54 : theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Ответ',
                  style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: textColor.withValues(alpha: 0.6)),
                ),
              ),
            if (message.isPinned)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.push_pin, size: 12, color: textColor.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text('Закреплено',
                        style: TextStyle(
                            fontSize: 11, color: textColor.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            if (message.isImage && message.fileUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: message.fileUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, _) => const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, _, _) => const SizedBox(
                    height: 150,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            if (message.isVoiceMessage)
              _VoiceBubble(message: message, isMine: isMine),
            if (message.isFile && message.fileUrl != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file, color: textColor, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Вложение',
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            if (message.text != null && message.text!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    top: message.fileUrl != null ? 6 : 0),
                child: Text(
                  message.text!,
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                      fontSize: 11, color: textColor.withValues(alpha: 0.5)),
                ),
                if (message.isEdited) ...[
                  const SizedBox(width: 4),
                  Text('ред.',
                      style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: textColor.withValues(alpha: 0.5))),
                ],
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == 'READ' ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.status == 'READ'
                        ? Colors.lightBlueAccent
                        : textColor.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMine;

  const _VoiceBubble({required this.message, required this.isMine});

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  double _progress = 0;
  StreamSubscription? _progressSub;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.stopPlayer();
      _progressSub?.cancel();
      if (mounted) setState(() { _isPlaying = false; _progress = 0; });
      return;
    }

    final url = widget.message.fileUrl;
    if (url == null || url.isEmpty) return;

    setState(() { _isPlaying = true; _progress = 0; });

    final totalMs = (widget.message.voiceDuration ?? 1) * 1000;
    _progressSub?.cancel();
    _progressSub = _player.onProgress?.listen((event) {
      if (mounted && totalMs > 0) {
        setState(() => _progress = event.position.inMilliseconds / totalMs);
      }
    });
    _player.setSubscriptionDuration(const Duration(milliseconds: 100));

    await _player.startPlayer(
      fromURI: url,
      whenFinished: () {
        if (mounted) setState(() { _isPlaying = false; _progress = 0; });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isMine ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final duration = widget.message.voiceDuration ?? 0;
    final mins = duration ~/ 60;
    final secs = duration % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Icon(
            _isPlaying ? Icons.stop : Icons.play_arrow,
            color: textColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 24,
                constraints: const BoxConstraints(maxWidth: 160),
                child: CustomPaint(
                  size: const Size(160, 24),
                  painter: _WaveformPainter(
                    color: textColor.withValues(alpha: 0.6),
                    progress: _progress,
                    activeColor: textColor,
                  ),
                ),
              ),
              Text(
                '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  final double progress;
  final Color activeColor;

  _WaveformPainter({
    required this.color,
    this.progress = 0,
    Color? activeColor,
  }) : activeColor = activeColor ?? color;

  @override
  void paint(Canvas canvas, Size size) {
    final inactivePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 30;
    final barWidth = size.width / (barCount * 2);
    final progressX = size.width * progress;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2 + barWidth;
      final h = (size.height * 0.3) +
          (size.height * 0.7 * ((i * 7 + 3) % 11) / 11);
      final y1 = (size.height - h) / 2;
      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y1 + h),
        x <= progressX ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
