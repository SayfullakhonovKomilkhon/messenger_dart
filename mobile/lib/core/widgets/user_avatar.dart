import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';

/// Аватар пользователя — квадрат с закруглёнными углами.
/// При ошибке загрузки показывает инициалы.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.radius = 24,
  });

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// Радиус скругления углов (пропорционально размеру)
  double get _cornerRadius => radius * 0.4;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null ||
        avatarUrl!.isEmpty ||
        !AppConstants.isValidImageUrl(avatarUrl)) {
      return _buildPlaceholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_cornerRadius),
      child: CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _buildPlaceholder(context),
        placeholder: (context, url) => SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Center(
            child: SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 1.0),
        borderRadius: BorderRadius.circular(_cornerRadius),
      ),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            fontSize: radius * 0.6,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
