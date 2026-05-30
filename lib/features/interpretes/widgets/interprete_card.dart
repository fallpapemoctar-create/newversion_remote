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
    final secondary = [
      if ((interprete.languesParlees ?? '').trim().isNotEmpty)
        interprete.languesParlees!.trim(),
      if ((interprete.ville ?? '').trim().isNotEmpty) interprete.ville!.trim(),
    ].join(' - ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interprete.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        secondary.isEmpty ? 'Cissam18' : secondary,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                StatusChip.fromString(interprete.status),
              ],
            ),
            const SizedBox(height: 18),
            if (interprete.telMobile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InfoRow(icon: Icons.phone_outlined, text: interprete.telMobile!),
              ),
            if (interprete.email != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InfoRow(icon: Icons.mail_outline, text: interprete.email!),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text('Contacter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _SquareActionButton(
                  icon: Icons.edit_outlined,
                  color: AppTheme.primary,
                  onPressed: onTap,
                ),
                const SizedBox(width: 8),
                _SquareActionButton(
                  icon: Icons.delete_outline,
                  color: AppTheme.danger,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _SquareActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Icon(icon, size: 24),
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
    return Row(
      children: [
        Icon(icon, size: 22, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
