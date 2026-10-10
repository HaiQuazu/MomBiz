import 'package:flutter/material.dart';

import '../theme/app_icons.dart';

/// Small, consistent action used inside customer/product pickers so a user
/// can create a missing record without leaving the current workflow.
class AppPickerCreateTile extends StatelessWidget {
  const AppPickerCreateTile({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  AppIcons.add,
                  size: 20,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                AppIcons.chevronRight,
                size: 20,
                color: colors.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
