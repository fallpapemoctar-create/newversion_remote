class InterpreteModel {
  final int id;
  final String? numero;
  final String displayName;
  final String firstname;
  final String lastname;
  final String? email;
  final String? telMobile;
  final String? telDomicile;
  final String? languesParlees;
  final String? adresse;
  final String? codePostal;
  final String? ville;
  final String? pays;
  final String? countryLabel;
  final int? fkCountry;
  final String? countryCode;
  final String status;
  final String? selectdispo;
  final String? commentaires;

  const InterpreteModel({
    required this.id,
    this.numero,
    required this.displayName,
    required this.firstname,
    required this.lastname,
    this.email,
    this.telMobile,
    this.telDomicile,
    this.languesParlees,
    this.adresse,
    this.codePostal,
    this.ville,
    this.pays,
    this.countryLabel,
    this.fkCountry,
    this.countryCode,
    required this.status,
    this.selectdispo,
    this.commentaires,
  });

  factory InterpreteModel.fromJson(Map<String, dynamic> json) {
    return InterpreteModel(
      id: json['id'] as int,
      numero: json['numero'] as String?,
      displayName: json['display_name'] as String? ?? '',
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      email: json['email'] as String?,
      telMobile: json['tel_mobile'] as String?,
      telDomicile: json['tel_domicile'] as String?,
      languesParlees: json['langues_parlees'] as String?,
      adresse: json['adresse'] as String?,
      codePostal: json['code_postal'] as String?,
      ville: json['ville'] as String?,
      pays: json['pays'] as String?,
      countryLabel: json['country_label'] as String?,
      fkCountry: json['fk_country'] as int?,
      countryCode: json['country_code'] as String?,
      status: json['status'] as String? ?? 'Indisponible',
      selectdispo: json['selectdispo'] as String?,
      commentaires: json['commentaires'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Numero': numero,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'tel_mobile': telMobile,
      'tel_domicile': telDomicile,
      'langues_parlees': languesParlees,
      'adresse': adresse,
      'code_postal': codePostal,
      'ville': ville,
      'pays': pays,
      'fk_country': fkCountry,
      'commentaires': commentaires,
      'selectdispo': selectdispo ?? status,
    };
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0];
    return '?';
  }

  List<String> get languesList =>
      languesParlees?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
}

