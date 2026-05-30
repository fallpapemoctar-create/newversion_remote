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

  Future<void> _showAddInterpreteDialog() async {
    final lastnameCtrl = TextEditingController();
    final firstnameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final languesCtrl = TextEditingController();
    final villeCtrl = TextEditingController();
    bool disponible = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Ajouter un interprète'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: lastnameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: firstnameCtrl,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: mobileCtrl,
                    decoration: const InputDecoration(labelText: 'Téléphone mobile'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: languesCtrl,
                    decoration: const InputDecoration(labelText: 'Langues parlées'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: villeCtrl,
                    decoration: const InputDecoration(labelText: 'Ville'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible'),
                    value: disponible,
                    onChanged: (v) => setLocalState(() => disponible = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final lastname = lastnameCtrl.text.trim();
                if (lastname.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nom est obligatoire.')),
                  );
                  return;
                }

                try {
                  await _service.add({
                    'lastname': lastname,
                    'firstname': firstnameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'tel_mobile': mobileCtrl.text.trim(),
                    'langues_parlees': languesCtrl.text.trim(),
                    'ville': villeCtrl.text.trim(),
                    'status': disponible ? 'Disponible' : 'Indisponible',
                  });
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
        const SnackBar(content: Text('Interprète ajouté.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F7FD), Color(0xFFEEF2F8)],
              ),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
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
                            'Annuaire des interprètes',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.article_outlined, color: AppTheme.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'FMI - Facturation des interprètes',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        '${_filtered.length} interprètes',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Rechercher un interprète par nom, langue, téléphone...',
                            prefixIcon: Icon(Icons.search_outlined, size: 30),
                          ),
                          onChanged: (v) => setState(() {
                            _search = v;
                            _applyFilter();
                          }),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _showFilters = !_showFilters),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryLight,
                              foregroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                            icon: const Icon(Icons.filter_list, size: 22),
                            label: const Text('Filtres', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                          if (_activeFilterCount > 0)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                                child: Center(
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        onPressed: _showAddInterpreteDialog,
                        icon: const Icon(Icons.add, size: 22),
                        label: const Text('Ajouter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
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
                            child: _GridContent(
                              items: _filtered,
                              onTap: _openMissions,
                              onDelete: _confirmDelete,
                            ),
                          ),
          ),
        ],
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

