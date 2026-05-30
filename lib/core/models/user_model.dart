class UserModel {
  final int id;
  final String prenom;
  final String nom;
  final String login;
  final List<String> rights;

  const UserModel({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.login,
    required this.rights,
  });

  String get displayName => '$prenom $nom'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        prenom: json['prenom'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        login: json['login'] as String? ?? '',
        rights: List<String>.from(json['rights'] ?? []),
      );

  bool hasRight(String right) => rights.contains(right);
}
