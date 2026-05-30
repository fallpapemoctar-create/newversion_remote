import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse(ApiConstants.getUsers));
      if (response.statusCode != 200) throw Exception('Erreur serveur');
      final data = json.decode(response.body);
      if (data is List) {
        if (mounted) {
          setState(() {
            _users = data.cast<Map<String, dynamic>>();
            _applyFilter();
            _loading = false;
          });
        }
      } else {
        throw Exception('Réponse inattendue');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _loading
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
                                value: '${_filtered.length}',
                                label: 'Actifs',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un utilisateur...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(_applyFilter);
                                    },
                                  ),
                            filled: true,
                            fillColor: AppTheme.surface,
                          ),
                          onChanged: (_) => setState(_applyFilter),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _AdminAction(
                              icon: Icons.table_chart_outlined,
                              label: 'Excel',
                              color: AppTheme.success,
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export Excel à venir')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _AdminAction(
                              icon: Icons.download_outlined,
                              label: 'CSV',
                              color: const Color(0xFF0EA5E9),
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export CSV à venir')),
                              ),
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
                                      onPressed: () {},
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Ajouter'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
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
