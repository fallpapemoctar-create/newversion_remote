class MissionModel {
  final int id;
  final String referenceDevis;
  final String? label;
  final int interpreteId;
  final String interpreteFirstname;
  final String interpreteLastname;
  final int? clientId;
  final String? clientName;
  final int? contactId;
  final String? dateMission;
  final String? heureDebutMission;
  final int? dureeMission;
  final String? debutMission;
  final String? finMission;
  final int missionStatus;
  final List<String> missionTypes;
  final String? produitRef;
  final String? produitLabel;
  final double? produitPrice;
  final int? idProduitService;
  final String? billedStatus;
  final String? clientBilledStatus;
  final String? clientInvoiceNumber;
  final String? commentaires;
  final String? dateCreation;

  const MissionModel({
    required this.id,
    required this.referenceDevis,
    this.label,
    required this.interpreteId,
    required this.interpreteFirstname,
    required this.interpreteLastname,
    this.clientId,
    this.clientName,
    this.contactId,
    this.dateMission,
    this.heureDebutMission,
    this.dureeMission,
    this.debutMission,
    this.finMission,
    this.missionStatus = 0,
    this.missionTypes = const [],
    this.produitRef,
    this.produitLabel,
    this.produitPrice,
    this.idProduitService,
    this.billedStatus,
    this.clientBilledStatus,
    this.clientInvoiceNumber,
    this.commentaires,
    this.dateCreation,
  });

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    List<String> types = [];
    final rawTypes = json['mission_types'];
    if (rawTypes is List) {
      types = rawTypes.map((e) => e.toString()).toList();
    } else if (rawTypes is String && rawTypes.isNotEmpty) {
      types = [rawTypes];
    }

    return MissionModel(
      id: _asInt(json['rowid'] ?? json['id']),
      referenceDevis: json['reference_devis'] as String? ?? '',
      label: json['label'] as String?,
      interpreteId: _asInt(json['nominterprete'] ?? json['interpreter_id']),
      interpreteFirstname: json['firstname'] as String? ?? '',
      interpreteLastname: json['lastname'] as String? ?? '',
      clientId: _asNullableInt(json['client_id']),
      clientName: json['client_name'] as String?,
      contactId: _asNullableInt(json['contact_id']),
      dateMission: json['datemission'] as String?,
      heureDebutMission: json['heuredebutmission'] as String?,
      dureeMission: _asNullableInt(json['dureemission']),
      debutMission: json['debutmission'] as String?,
      finMission: json['finmission'] as String?,
      missionStatus: _asInt(json['mission_status']),
      missionTypes: types,
      produitRef: json['produit_ref'] as String?,
      produitLabel: json['produit_label'] as String?,
      produitPrice: _asNullableDouble(json['produit_price']),
      idProduitService: _asNullableInt(json['id_produit_service']),
      billedStatus: json['billed_status'] as String?,
      clientBilledStatus: json['client_billed_status'] as String?,
      clientInvoiceNumber: json['client_invoice_number'] as String?,
      commentaires: json['commentaires'] as String?,
      dateCreation: json['date_creation_iso'] as String? ?? json['date_creation'] as String?,
    );
  }

  String get interpreteName => '$interpreteFirstname $interpreteLastname';

  String get statusLabel {
    switch (missionStatus) {
      case 0: return 'En attente';
      case 1: return 'Confirmée';
      case 2: return 'En cours';
      case 3: return 'Terminée';
      case 9: return 'Annulée';
      default: return 'Inconnue';
    }
  }
}

