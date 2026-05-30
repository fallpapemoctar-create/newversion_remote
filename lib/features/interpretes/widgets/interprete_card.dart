import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/interprete_model.dart';

class InterpreteCard extends StatelessWidget {
  final InterpreteModel interprete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InterpreteCard({
    super.key,
    required this.interprete,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    interprete.initials,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interprete.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (interprete.numero != null)
                        Text(
                          '#${interprete.numero}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                ),
                StatusChip.fromString(interprete.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details
            if (interprete.email != null)
              _InfoRow(icon: Icons.email_outlined, text: interprete.email!),
            if (interprete.telMobile != null)
              _InfoRow(icon: Icons.phone_outlined, text: interprete.telMobile!),
            if (interprete.ville != null)
              _InfoRow(icon: Icons.location_on_outlined, text: interprete.ville!),

            // Languages
            if (interprete.languesList.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: interprete.languesList.take(3).map((l) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l,
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary),
                  ),
                )).toList(),
              ),
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Voir missions', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: AppTheme.danger,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
                    ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
