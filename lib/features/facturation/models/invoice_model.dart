class InvoiceModel {
  final int id;
  final String ref;
  final String clientName;
  final double totalHT;
  final double totalTTC;
  final int fkStatut; // 0=Brouillon, 1=Envoyée, 2=Payée, 3=Abandonnée
  final String? date;

  const InvoiceModel({
    required this.id,
    required this.ref,
    required this.clientName,
    required this.totalHT,
    required this.totalTTC,
    required this.fkStatut,
    this.date,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> j) {
    // date_invoice can be a unix timestamp (int/string) or a date string
    String? dateStr;
    final raw = j['date_invoice'] ?? j['date'];
    if (raw != null) {
      final ts = int.tryParse(raw.toString());
      if (ts != null && ts > 1000000000) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } else {
        dateStr = raw.toString();
      }
    }

    return InvoiceModel(
      id: int.tryParse(j['rowid']?.toString() ?? '') ?? 0,
      ref: j['ref']?.toString() ?? '',
      clientName: j['nom']?.toString() ?? j['name']?.toString() ?? '',
      totalHT: double.tryParse(j['total_ht']?.toString() ?? '') ?? 0.0,
      totalTTC: double.tryParse(j['total_ttc']?.toString() ?? '') ?? 0.0,
      fkStatut: int.tryParse(j['fk_statut']?.toString() ?? '') ?? 0,
      date: dateStr,
    );
  }

  String get statusLabel {
    switch (fkStatut) {
      case 0:
        return 'Brouillon';
      case 1:
        return 'Envoyée';
      case 2:
        return 'Payée';
      case 3:
        return 'Abandonnée';
      default:
        return 'Inconnu';
    }
  }
}
