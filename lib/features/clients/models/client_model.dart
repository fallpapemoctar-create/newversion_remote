class ClientModel {
  final int id;
  final String name;
  final String? alias;
  final String? address;
  final String? zip;
  final String? town;
  final String? phone;
  final String? fax;
  final String? email;
  final String? website;
  final String? siren;
  final String? siret;
  final String? notePublic;
  final String? notePrivate;
  final int? fkPays;
  final String? countryLabel;
  final int? fkDepartement;
  final String? departmentLabel;
  final int status;

  const ClientModel({
    required this.id,
    required this.name,
    this.alias,
    this.address,
    this.zip,
    this.town,
    this.phone,
    this.fax,
    this.email,
    this.website,
    this.siren,
    this.siret,
    this.notePublic,
    this.notePrivate,
    this.fkPays,
    this.countryLabel,
    this.fkDepartement,
    this.departmentLabel,
    this.status = 1,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      alias: json['alias'] as String?,
      address: json['address'] as String?,
      zip: json['zip'] as String?,
      town: json['town'] as String?,
      phone: json['phone'] as String?,
      fax: json['fax'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      siren: json['siren'] as String?,
      siret: json['siret'] as String?,
      notePublic: json['note_public'] as String?,
      notePrivate: json['note_private'] as String?,
      fkPays: json['fk_pays'] as int?,
      countryLabel: json['country_label'] as String?,
      fkDepartement: json['fk_departement'] as int?,
      departmentLabel: json['department_label'] as String?,
      status: json['status'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'alias': alias,
        'address': address,
        'zip': zip,
        'town': town,
        'phone': phone,
        'fax': fax,
        'email': email,
        'website': website,
        'siren': siren,
        'siret': siret,
        'note_public': notePublic,
        'note_private': notePrivate,
        'fk_pays': fkPays,
        'fk_departement': fkDepartement,
      };

  String get displayAddress {
    final parts = [address, zip, town].where((e) => e != null && e.isNotEmpty);
    return parts.join(', ');
  }
}
