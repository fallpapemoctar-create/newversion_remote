import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  bool _showFilters = false;

  int get _activeCount {
    return _filtered.where((u) {
      final active = u['is_active'];
      if (active is bool) return active;
      return (u['statut']?.toString() == '1');
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> _normalizeUser(Map<String, dynamic> raw) {
    final fullname = (raw['fullname'] ?? '').toString().trim();
    final firstname = (raw['firstname'] ?? '').toString().trim();
    final lastname = (raw['lastname'] ?? '').toString().trim();
    final username = (raw['username'] ?? raw['login'] ?? '').toString().trim();

    String first = firstname;
    String last = lastname;
    if ((first.isEmpty && last.isEmpty) && fullname.isNotEmpty) {
      final parts = fullname.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        first = parts.first;
        last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    return {
      ...raw,
      'firstname': first,
      'lastname': last,
      'login': username,
    };
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse(ApiConstants.getUsers));
      if (response.statusCode != 200) throw Exception('Erreur serveur');
      final data = json.decode(response.body);

      List<Map<String, dynamic>> users;
      if (data is List) {
        users = data.cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw Exception((data['details'] ?? data['error'] ?? 'Erreur API').toString());
        }
        final rawUsers = data['users'] ?? data['data'];
        if (rawUsers is List) {
          users = rawUsers.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Réponse inattendue');
        }
      } else {
        throw Exception('Réponse inattendue');
      }

      if (mounted) {
        setState(() {
          _users = users.map(_normalizeUser).toList();
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_users);
      return;
    }
    _filtered = _users.where((u) {
      final name = '${u['firstname'] ?? ''} ${u['lastname'] ?? ''}'.trim().toLowerCase();
      final login = (u['login'] ?? '').toString().toLowerCase();
      return name.contains(q) || login.contains(q);
    }).toList();
  }

  Future<void> _exportCsv() async {
    final rows = <String>[
      'Id;Nom;Login;Statut',
      ..._filtered.map((u) {
        final id = (u['rowid'] ?? u['id'] ?? '').toString();
        final name = '${u['firstname'] ?? ''} ${u['lastname'] ?? ''}'.trim();
        final login = (u['login'] ?? '').toString();
        final active = u['is_active'] == true || u['statut']?.toString() == '1';
        return '$id;$name;$login;${active ? 'Actif' : 'Inactif'}';
      }),
    ];

    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export copie (${_filtered.length} lignes).')),
    );
  }

  Future<void> _showAddUserDialog() async {
    final usernameCtrl = TextEditingController();
    final fullnameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isAdmin = false;
    bool canManageInterpreters = true;
    bool canManageMissions = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Ajouter un utilisateur'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Login *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: fullnameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe *'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Administrateur'),
                    value: isAdmin,
                    onChanged: (v) => setLocalState(() => isAdmin = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gerer les interpretes'),
                    value: canManageInterpreters,
                    onChanged: (v) => setLocalState(() => canManageInterpreters = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gerer les missions'),
                    value: canManageMissions,
                    onChanged: (v) => setLocalState(() => canManageMissions = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final username = usernameCtrl.text.trim();
                final password = passwordCtrl.text;
                if (username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Login et mot de passe obligatoires.')),
                  );
                  return;
                }

                try {
                  final response = await http.post(
                    Uri.parse(ApiConstants.addUser),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'username': username,
                      'fullname': fullnameCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'password': password,
                      'is_admin': isAdmin,
                      'can_manage_interpreters': canManageInterpreters,
                      'can_manage_missions': canManageMissions,
                    }),
                  );
                  final data = json.decode(response.body) as Map<String, dynamic>;
                  if (response.statusCode != 200 || data['success'] != true) {
                    throw Exception((data['error'] ?? data['message'] ?? 'Erreur API').toString());
                  }

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx, true);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                  );
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur ajouté.')),
      );
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id = int.tryParse((user['rowid'] ?? user['id'] ?? '').toString());
    if (id == null || id <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID utilisateur invalide.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    final name = '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Supprimer $name ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.deleteUser),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id}),
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception((data['error'] ?? data['message'] ?? 'Erreur suppression').toString());
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _showUserActions(Map<String, dynamic> user) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
              title: const Text('Supprimer'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'delete') {
      await _deleteUser(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administration',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_filtered.length} utilisateur(s)',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.refresh_outlined, size: 22),
                      label: const Text('Rafraichir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.person_add_outlined, size: 22),
                      label: const Text('Ajouter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      prefixIcon: const Icon(Icons.search, size: 24),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(_applyFilter);
                              },
                            ),
                    ),
                    onChanged: (_) => setState(_applyFilter),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger)))
                    : _filtered.isEmpty && _users.isEmpty
                        ? const EmptyState(icon: Icons.group_outlined, title: 'Aucun utilisateur')
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                        Row(
                          children: [
                            Expanded(
                              child: _AdminKpi(
                                icon: Icons.groups_outlined,
                                iconColor: AppTheme.primary,
                                iconBg: AppTheme.primary.withValues(alpha: 0.1),
                                value: '${_filtered.length}',
                                label: 'Utilisateurs',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _AdminKpi(
                                icon: Icons.admin_panel_settings_outlined,
                                iconColor: AppTheme.success,
                                iconBg: AppTheme.success.withValues(alpha: 0.1),
                                value: '$_activeCount',
                                label: 'Actifs',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _AdminAction(
                              icon: Icons.table_chart_outlined,
                              label: 'Excel',
                              color: AppTheme.success,
                              onTap: _exportCsv,
                            ),
                            const SizedBox(width: 8),
                            _AdminAction(
                              icon: Icons.download_outlined,
                              label: 'CSV',
                              color: const Color(0xFF0EA5E9),
                              onTap: _exportCsv,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.filter_list_outlined),
                              onPressed: () => setState(() => _showFilters = !_showFilters),
                            ),
                          ],
                        ),
                        if (_showFilters)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Filtre rapide: utilisez la barre de recherche par nom ou login.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ),
                        // Section header
                        Row(
                          children: [
                            const Text(
                              'Utilisateurs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_filtered.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: _filtered.asMap().entries.map((entry) {
                              final u = entry.value;
                              final isLast = entry.key == _filtered.length - 1;
                              final name = '${u['firstname'] ?? ''} ${u['lastname'] ?? ''}'.trim();
                              final login = u['login']?.toString() ?? '';
                              return Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                      child: Text(
                                        name.isNotEmpty ? name[0] : '?',
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '@$login',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert_outlined, size: 18),
                                      onPressed: () => _showUserActions(u),
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(height: 1, indent: 56),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _AdminKpi extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _AdminKpi({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
