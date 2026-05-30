import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import 'models/interprete_model.dart';
import 'services/interpretes_service.dart';
import 'widgets/interprete_card.dart';
import '../missions/missions_screen.dart';

class InterpretesScreen extends StatefulWidget {
  const InterpretesScreen({super.key});

  @override
  State<InterpretesScreen> createState() => _InterpretesScreenState();
}

class _InterpretesScreenState extends State<InterpretesScreen> {
  final _service = InterpretesService();
  List<InterpreteModel> _all = [];
  List<InterpreteModel> _filtered = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  bool _gridView = true;
  bool _showFilters = false;
  String _statusFilter = 'all';
  String _cityFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getAll();
      if (mounted) {
        setState(() {
        _all = data;
        _applyFilter();
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    final city = _cityFilter.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_all)
        : _all.where((i) =>
            i.displayName.toLowerCase().contains(q) ||
            (i.email?.toLowerCase().contains(q) ?? false) ||
            (i.languesParlees?.toLowerCase().contains(q) ?? false) ||
            (i.ville?.toLowerCase().contains(q) ?? false)).toList();

    if (_statusFilter != 'all') {
      _filtered = _filtered.where((i) {
        final status = i.status.toLowerCase();
        if (_statusFilter == 'disponible') {
          return status.contains('disponible') && !status.contains('indisponible');
        }
        if (_statusFilter == 'indisponible') {
          return status.contains('indisponible');
        }
        return true;
      }).toList();
    }

    if (city.isNotEmpty) {
      _filtered = _filtered
          .where((i) => (i.ville ?? '').toLowerCase().contains(city))
          .toList();
    }
  }

  int get _availableCount {
    return _filtered.where((i) {
      final s = i.status.toLowerCase();
      return s.contains('disponible') && !s.contains('indisponible');
    }).length;
  }

  int get _unavailableCount {
    return _filtered.where((i) {
      final s = i.status.toLowerCase();
      return s.contains('indisponible');
    }).length;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_statusFilter != 'all') count++;
    if (_cityFilter.trim().isNotEmpty) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = 'all';
      _cityFilter = '';
      _applyFilter();
    });
  }

  Future<void> _confirmDelete(InterpreteModel i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'interprète'),
        content: Text('Supprimer ${i.displayName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(i.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _openMissions(InterpreteModel i) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MissionsScreen(interpreteId: i.id, interpreteNom: i.displayName),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interprètes',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_filtered.length} interprète(s)',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_gridView ? Icons.view_list_outlined : Icons.grid_view_outlined),
                  onPressed: () => setState(() => _gridView = !_gridView),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list_outlined),
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$_activeFilterCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un interprète...',
                      prefixIcon: Icon(Icons.search_outlined, size: 18),
                    ),
                    onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
                  ),
                ),
                const SizedBox(width: 10),
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_filtered.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    icon: Icons.people_outline,
                    iconColor: AppTheme.primary,
                    iconBg: AppTheme.primary.withValues(alpha: 0.1),
                    value: '${_filtered.length}',
                    label: 'Total',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiCard(
                    icon: Icons.check_circle_outline,
                    iconColor: AppTheme.success,
                    iconBg: AppTheme.success.withValues(alpha: 0.1),
                    value: '$_availableCount',
                    label: 'Disponibles',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiCard(
                    icon: Icons.remove_circle_outline,
                    iconColor: AppTheme.danger,
                    iconBg: AppTheme.danger.withValues(alpha: 0.1),
                    value: '$_unavailableCount',
                    label: 'Indisponibles',
                  ),
                ),
              ],
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                _showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Filtres avancés',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Réinitialiser'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Statut', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
                      DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                      DropdownMenuItem(value: 'indisponible', child: Text('Indisponible')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _statusFilter = v ?? 'all';
                        _applyFilter();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      hintText: 'Filtrer par ville',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _cityFilter = v;
                        _applyFilter();
                      });
                    },
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.table_chart_outlined,
                  label: 'Excel',
                  color: AppTheme.success,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export Excel à venir')),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.download_outlined,
                  label: 'CSV',
                  color: const Color(0xFF0EA5E9),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export CSV à venir')),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger)))
                    : _filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.people_outline,
                            title: 'Aucun interprète trouvé',
                            subtitle: _search.isNotEmpty ? 'Modifiez votre recherche' : null,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: _gridView
                                ? _GridContent(
                                    items: _filtered,
                                    onTap: _openMissions,
                                    onDelete: _confirmDelete,
                                  )
                                : _ListContent(
                                    items: _filtered,
                                    onTap: _openMissions,
                                    onDelete: _confirmDelete,
                                  ),
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

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _KpiCard({
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _GridContent extends StatelessWidget {
  final List<InterpreteModel> items;
  final ValueChanged<InterpreteModel> onTap;
  final ValueChanged<InterpreteModel> onDelete;
  const _GridContent({required this.items, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 700 ? 3 : constraints.maxWidth > 450 ? 2 : 1;
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => InterpreteCard(
          interprete: items[i],
          onTap: () => onTap(items[i]),
          onDelete: () => onDelete(items[i]),
        ),
      );
    });
  }
}

class _ListContent extends StatelessWidget {
  final List<InterpreteModel> items;
  final ValueChanged<InterpreteModel> onTap;
  final ValueChanged<InterpreteModel> onDelete;
  const _ListContent({required this.items, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => InterpreteCard(
        interprete: items[i],
        onTap: () => onTap(items[i]),
        onDelete: () => onDelete(items[i]),
      ),
    );
  }
}
