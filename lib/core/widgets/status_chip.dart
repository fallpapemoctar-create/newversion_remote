import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusType {
  disponible,
  indisponible,
  pending,
  // facture / devis
  brouillon,
  envoye,
  validee,
  terminee,
  annulee,
  expire,
  occupe,
  special,
  valide,
  verrouille,
  unknown,
}

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusChip({super.key, required this.label, this.type = StatusType.unknown});

  factory StatusChip.fromString(String? status) {
    final s = (status ?? '').toLowerCase().trim();
    StatusType t;
    if (s == 'disponible') {
      t = StatusType.disponible;
    } else if (s == 'indisponible' || s == 'unavailable') {
      t = StatusType.indisponible;
    } else if (s == 'occupé' || s == 'occupe') {
      t = StatusType.occupe;
    } else if (s == 'brouillon' || s == 'draft') {
      t = StatusType.brouillon;
    } else if (s == 'envoyé' || s == 'envoye' || s == 'sent') {
      t = StatusType.envoye;
    } else if (s == 'validée' || s == 'validee' || s == 'accepted' || s == 'confirmée' || s == 'confirmee') {
      t = StatusType.validee;
    } else if (s == 'terminée' || s == 'terminee' || s == 'finished' || s == 'completed') {
      t = StatusType.terminee;
    } else if (s == 'annulée' || s == 'annulee' || s == 'cancelled' || s == 'rejected') {
      t = StatusType.annulee;
    } else if (s == 'expiré' || s == 'expire' || s == 'expired') {
      t = StatusType.expire;
    } else if (s == 'spécial' || s == 'special') {
      t = StatusType.special;
    } else if (s == 'validé' || s == 'valide' || s == 'validated') {
      t = StatusType.valide;
    } else if (s == 'verrouillé' || s == 'verrouille' || s == 'locked') {
      t = StatusType.verrouille;
    } else if (s.contains('attente') || s == 'pending' || s == 'en cours') {
      t = StatusType.pending;
    } else {
      t = StatusType.unknown;
    }
    return StatusChip(label: status ?? '—', type: t);
  }

  ({Color bg, Color fg}) get _colors {
    switch (type) {
      case StatusType.disponible:
      case StatusType.validee:
      case StatusType.terminee:
        return (bg: AppTheme.statusAcceptBg, fg: AppTheme.statusAcceptFg);
      case StatusType.indisponible:
      case StatusType.annulee:
        return (bg: AppTheme.statusRejectBg, fg: AppTheme.statusRejectFg);
      case StatusType.occupe:
      case StatusType.expire:
      case StatusType.pending:
        return (bg: AppTheme.statusExpiredBg, fg: AppTheme.statusExpiredFg);
      case StatusType.brouillon:
        return (bg: AppTheme.statusDraftBg, fg: AppTheme.statusDraftFg);
      case StatusType.envoye:
        return (bg: AppTheme.statusSentBg, fg: AppTheme.statusSentFg);
      case StatusType.special:
        return (bg: AppTheme.statusSpecialBg, fg: AppTheme.statusSpecialFg);
      case StatusType.valide:
        return (bg: AppTheme.statusValidBg, fg: AppTheme.statusValidFg);
      case StatusType.verrouille:
        return (bg: AppTheme.statusLockedBg, fg: AppTheme.statusLockedFg);
      case StatusType.unknown:
        return (bg: AppTheme.statusDraftBg, fg: AppTheme.statusDraftFg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c.fg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
