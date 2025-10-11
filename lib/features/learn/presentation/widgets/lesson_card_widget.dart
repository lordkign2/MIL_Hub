import 'package:flutter/material.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../../../../core/constants/app_constants.dart';

class LessonCardWidget extends StatelessWidget {
  final LessonEntity lesson;
  final int progress;
  final VoidCallback? onTap;

  const LessonCardWidget({
    super.key,
    required this.lesson,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _getColorFromHex(lesson.color)?.withOpacity(0.2) ??
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(lesson.icon),
                      color:
                          _getColorFromHex(lesson.color) ??
                          Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorFromHex(lesson.color) ??
                      Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$progress% complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'visibility':
        return Icons.visibility;
      case 'shield':
        return Icons.shield;
      case 'balance':
        return Icons.balance;
      default:
        return Icons.school;
    }
  }

  Color? _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;

    try {
      // Remove the '0x' prefix if present
      final hex = hexColor.startsWith('0x') ? hexColor.substring(2) : hexColor;

      // Parse the hex color
      final colorValue = int.parse(hex, radix: 16);
      return Color(colorValue);
    } catch (e) {
      return null;
    }
  }
}
