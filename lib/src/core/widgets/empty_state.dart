import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A calm, centered empty/placeholder state: a muted icon over a short message.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.hint});

  final IconData icon;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSub.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w600, fontSize: 15),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSub.withValues(alpha: 0.8), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
