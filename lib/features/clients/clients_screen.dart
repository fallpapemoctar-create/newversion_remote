import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import 'models/client_model.dart';
import 'services/clients_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _service = ClientsService();
  final _searchCtrl = TextEditingController();
  List<ClientModel> _clients = [];
  List<ClientModel> _filtered = [];
  bool _loading = true;
  String? _error;
  bool _showFilters = false;
  bool _activeOnly = true;
  String _cityFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? q}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getAll(q: q, activeOnly: _activeOnly);
      setState(() {
        _clients = list;
        _applyLocalFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyLocalFilters() {
    final city = _cityFilter.toLowerCase();
    _filtered = city.isEmpty
        ? List.from(_clients)
        : _clients.where((c) => (c.town ?? '').toLowerCase().contains(city)).toList();
  }

  int get _activeCount => _filtered.where((c) => c.status == 1).length;
  int get _inactiveCount => _filtered.where((c) => c.status != 1).length;
  int get _activeFilterCount => _cityFilter.trim().isEmpty ? 0 : 1;

  void _resetFilters() {
    setState(() {
      _cityFilter = '';
      _applyLocalFilters();
    });
  }

  Future<void> _confirmDelete(ClientModel client) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver ce client ?'),
        content: Text('${client.name} sera désactivé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.delete(client.id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e'), backgroundColor: AppTheme.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tiers', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text('${_filtered.length} client(s)',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      icon: const Icon(Icons.filter_list_outlined),
                      tooltip: 'Filtres',
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
                FilledButton.icon(
                  onPressed: () => _showClientForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau client'),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                filled: true,
                fillColor: AppTheme.surface,
              ),
              onChanged: (v) => _load(q: v),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _ClientsKpi(
                    icon: Icons.business_outlined,
                    iconColor: AppTheme.primary,
                    iconBg: AppTheme.primary.withValues(alpha: 0.1),
                    value: '${_filtered.length}',
                    label: 'Total',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ClientsKpi(
                    icon: Icons.check_circle_outline,
                    iconColor: AppTheme.success,
                    iconBg: AppTheme.success.withValues(alpha: 0.1),
                    value: '$_activeCount',
                    label: 'Actifs',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ClientsKpi(
                    icon: Icons.remove_circle_outline,
                    iconColor: AppTheme.danger,
                    iconBg: AppTheme.danger.withValues(alpha: 0.1),
                    value: '$_inactiveCount',
                    label: 'Inactifs',
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _activeOnly,
                    title: const Text('Afficher uniquement les clients actifs'),
                    onChanged: (v) {
                      setState(() => _activeOnly = v);
                      _load(q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      hintText: 'Filtrer par ville',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _cityFilter = v;
                        _applyLocalFilters();
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
                _ClientsAction(
                  icon: Icons.table_chart_outlined,
                  label: 'Excel',
                  color: AppTheme.success,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export Excel à venir')),
                  ),
                ),
                const SizedBox(width: 8),
                _ClientsAction(
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
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: AppTheme.danger)),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _load, child: const Text('Réessayer')),
                        ],
                      ))
                    : _filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.business_outlined,
                            title: 'Aucun client',
                            subtitle: 'Commencez par ajouter un client.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _ClientCard(
                              client: _filtered[i],
                              onEdit: () => _showClientForm(client: _filtered[i]),
                              onDelete: () => _confirmDelete(_filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showClientForm({ClientModel? client}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ClientFormSheet(
        client: client,
        onSaved: _load,
      ),
    );
  }
}

class _ClientsKpi extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _ClientsKpi({
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

class _ClientsAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ClientsAction({
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

class _ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({required this.client, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(client.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.displayAddress.isNotEmpty)
              Text(client.displayAddress,
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            if (client.phone != null && client.phone!.isNotEmpty)
              Text(client.phone!,
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Modifier',
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
              tooltip: 'Désactiver',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientFormSheet extends StatefulWidget {
  final ClientModel? client;
  final VoidCallback onSaved;

  const _ClientFormSheet({this.client, required this.onSaved});

  @override
  State<_ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends State<_ClientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = ClientsService();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _alias;
  late final TextEditingController _address;
  late final TextEditingController _zip;
  late final TextEditingController _town;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _siren;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _name = TextEditingController(text: c?.name);
    _alias = TextEditingController(text: c?.alias);
    _address = TextEditingController(text: c?.address);
    _zip = TextEditingController(text: c?.zip);
    _town = TextEditingController(text: c?.town);
    _phone = TextEditingController(text: c?.phone);
    _email = TextEditingController(text: c?.email);
    _siren = TextEditingController(text: c?.siren);
  }

  @override
  void dispose() {
    for (final c in [_name, _alias, _address, _zip, _town, _phone, _email, _siren]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        if (widget.client != null) 'id': widget.client!.id,
        'name': _name.text.trim(),
        'alias': _alias.text.trim(),
        'address': _address.text.trim(),
        'zip': _zip.text.trim(),
        'town': _town.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'siren': _siren.text.trim(),
      };
      if (widget.client == null) {
        await _service.add(data);
      } else {
        await _service.update(data);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.client != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'Modifier le client' : 'Nouveau client',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _alias, decoration: const InputDecoration(labelText: 'Alias / Code')),
              const SizedBox(height: 12),
              TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Adresse')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _zip, decoration: const InputDecoration(labelText: 'Code postal'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: TextFormField(controller: _town, decoration: const InputDecoration(labelText: 'Ville'))),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone')),
              const SizedBox(height: 12),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextFormField(controller: _siren, decoration: const InputDecoration(labelText: 'SIREN')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Enregistrer' : 'Créer le client'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
