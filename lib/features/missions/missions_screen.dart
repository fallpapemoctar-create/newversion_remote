import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_chip.dart';
import '../interpretes/services/interpretes_service.dart';
import 'models/mission_model.dart';
import 'services/missions_service.dart';

class MissionsScreen extends StatefulWidget {
  final int? interpreteId;
  final String? interpreteNom;

  const MissionsScreen({super.key, this.interpreteId, this.interpreteNom});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final _service = MissionsService();
  final _searchCtrl = TextEditingController();
  final _dateStartCtrl = TextEditingController();
  final _dateEndCtrl = TextEditingController();

  List<MissionModel> _missions = [];
  int _total = 0;
  bool _loading = true;
  String? _error;

  int _page = 1;
  static const int _pageSize = 50;

  bool _showFilters = false;
  bool _showStats = false;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _dateStartCtrl.dispose();
    _dateEndCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.interpreteId != null) {
        final data = await _service.getByInterprete(widget.interpreteId!);
        if (mounted) {
          setState(() {
            _missions = data;
            _total = data.length;
            _loading = false;
          });
        }
      } else {
        final result = await _service.getDataTable(
          page: _page,
          pageSize: _pageSize,
          q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          dateStart:
              _dateStartCtrl.text.trim().isEmpty ? null : _dateStartCtrl.text.trim(),
          dateEnd: _dateEndCtrl.text.trim().isEmpty ? null : _dateEndCtrl.text.trim(),
          missionStatus:
              _statusFilter == 'all' ? null : int.tryParse(_statusFilter),
        );
        if (mounted) {
          setState(() {
            _missions = result['missions'] as List<MissionModel>;
            _total = result['total'] as int;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  int get _totalPages => (_total / _pageSize).ceil().clamp(1, 999999);

  int get _activeFilterCount {
    int count = 0;
    if (_statusFilter != 'all') count++;
    if (_dateStartCtrl.text.trim().isNotEmpty) count++;
    if (_dateEndCtrl.text.trim().isNotEmpty) count++;
    return count;
  }

  void _applyFilters() => _load(reset: true);

  void _resetFilters() {
    _dateStartCtrl.clear();
    _dateEndCtrl.clear();
    setState(() {
      _statusFilter = 'all';
    });
    _load(reset: true);
  }

  Future<void> _exportCsv() async {
    final rows = <String>[
      'Reference;Interprete;Client;Date;Statut',
      ..._missions.map((m) {
        final ref = m.referenceDevis.isNotEmpty ? m.referenceDevis : 'Mission #${m.id}';
        return '$ref;${m.interpreteName};${m.clientName ?? ''};${_formatDate(m.dateMission ?? m.debutMission)};${m.statusLabel}';
      }),
    ];

    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export CSV copie (${_missions.length} lignes).')),
    );
  }

  Widget _buildStatsPanel() {
    final pending = _missions.where((m) => m.missionStatus == 0).length;
    final confirmed = _missions.where((m) => m.missionStatus == 1).length;
    final inProgress = _missions.where((m) => m.missionStatus == 2).length;
    final done = _missions.where((m) => m.missionStatus == 3).length;
    final cancelled = _missions.where((m) => m.missionStatus == 9).length;

    final items = [
      ('En attente', pending, AppTheme.statusExpiredFg, AppTheme.statusExpiredBg),
      ('Confirmées', confirmed, AppTheme.statusSentFg, AppTheme.statusSentBg),
      ('En cours', inProgress, AppTheme.primary, AppTheme.primarySoft),
      ('Terminées', done, AppTheme.statusAcceptFg, AppTheme.statusAcceptBg),
      ('Annulées', cancelled, AppTheme.statusRejectFg, AppTheme.statusRejectBg),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Page courante · $_total missions au total',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final (label, count, fg, bg) = item;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateMissionDialog() async {
    final interpretes = await InterpretesService().getAll();
    if (!mounted) return;
    if (interpretes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun interprete disponible pour creer une mission.')),
      );
      return;
    }

    int selectedInterpreterId = interpretes.first.id;
    final labelCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final startCtrl = TextEditingController(text: '09:00');
    final durationCtrl = TextEditingController(text: '60');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Nouvelle mission'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedInterpreterId,
                  decoration: const InputDecoration(labelText: 'Interprete'),
                  items: interpretes
                      .map((i) => DropdownMenuItem(value: i.id, child: Text(i.displayName)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setLocalState(() => selectedInterpreterId = v);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Libelle')),
                const SizedBox(height: 10),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
                const SizedBox(height: 10),
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Heure debut (HH:mm)')),
                const SizedBox(height: 10),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duree (minutes)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _service.add({
                    'interpreter_id': selectedInterpreterId,
                    'label': labelCtrl.text.trim(),
                    'datemission': dateCtrl.text.trim(),
                    'heuredebutmission': startCtrl.text.trim(),
                    'dureemission': int.tryParse(durationCtrl.text.trim()) ?? 60,
                    'mission_status': 1,
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
              child: const Text('Creer'),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      await _load(reset: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission creee avec succes.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.interpreteId == null)
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
                              'Gestion des missions',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_total mission${_total > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _showStats = !_showStats),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showStats ? AppTheme.primarySoft : AppTheme.surface,
                          foregroundColor: _showStats ? AppTheme.primary : AppTheme.textPrimary,
                          side: BorderSide(color: _showStats ? AppTheme.primary : AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.trending_up, size: 16),
                        label: Text(_showStats ? 'Masquer stats' : 'Statistiques', style: const TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _showFilters = !_showFilters),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _showFilters ? AppTheme.primarySoft : AppTheme.surface,
                              foregroundColor: _showFilters ? AppTheme.primary : AppTheme.textPrimary,
                              side: BorderSide(color: _showFilters ? AppTheme.primary : AppTheme.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.filter_list, size: 16),
                            label: const Text('Filtres', style: TextStyle(fontSize: 13)),
                          ),
                          if (_activeFilterCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 22,
                                height: 22,
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
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                          onPressed: _showCreateMissionDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Nouvelle mission', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Recherche par référence, client, interprète, langue...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppTheme.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                _load();
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _load(),
                  ),
                ],
              ),
            ),

          if (widget.interpreteId == null)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState:
                  _showStats ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: _buildStatsPanel(),
              secondChild: const SizedBox.shrink(),
            ),

          if (widget.interpreteId == null)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState:
                  _showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
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
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
                        DropdownMenuItem(value: '0', child: Text('En attente')),
                        DropdownMenuItem(value: '1', child: Text('Confirmée')),
                        DropdownMenuItem(value: '2', child: Text('En cours')),
                        DropdownMenuItem(value: '3', child: Text('Terminée')),
                        DropdownMenuItem(value: '9', child: Text('Annulée')),
                      ],
                      onChanged: (v) {
                        setState(() => _statusFilter = v ?? 'all');
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dateStartCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date début',
                              hintText: 'jj/mm/aaaa',
                              isDense: true,
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                            ),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) {
                                _dateStartCtrl.text =
                                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _dateEndCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date fin',
                              hintText: 'jj/mm/aaaa',
                              isDense: true,
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                            ),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) {
                                _dateEndCtrl.text =
                                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _applyFilters,
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Appliquer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),

          if (widget.interpreteId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel',
                    color: AppTheme.success,
                    onTap: _exportCsv,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.download_outlined,
                    label: 'CSV',
                    color: const Color(0xFF0EA5E9),
                    onTap: _exportCsv,
                  ),
                  const Spacer(),
                  if (_total > _pageSize)
                    Text(
                      'Page $_page / $_totalPages',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _load, child: const Text('Réessayer')),
                        ],
                      ),
                      )
                    : _missions.isEmpty
                        ? const EmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'Aucune mission trouvée',
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _missions.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _MissionCard(
                                mission: _missions[i],
                                formatDate: _formatDate,
                              ),
                            ),
                          ),
          ),

          if (widget.interpreteId == null && _total > _pageSize)
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _page > 1
                        ? () {
                            _page--;
                            _load(reset: false);
                          }
                        : null,
                  ),
                  Text('Page $_page / $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _page < _totalPages
                        ? () {
                            _page++;
                            _load(reset: false);
                          }
                        : null,
                  ),
                ],
              ),
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

class _MissionCard extends StatelessWidget {
  final MissionModel mission;
  final String Function(String?) formatDate;

  const _MissionCard({required this.mission, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.referenceDevis.isNotEmpty
                      ? mission.referenceDevis
                      : 'Mission #${mission.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              StatusChip.fromString(mission.statusLabel),
            ],
          ),
          if (mission.label != null && mission.label!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(mission.label!, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _InfoChip(
                icon: Icons.person_outline,
                label: mission.interpreteName,
              )),
              if (mission.clientName != null)
                Expanded(child: _InfoChip(
                  icon: Icons.business_outlined,
                  label: mission.clientName!,
                )),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: formatDate(mission.dateMission ?? mission.debutMission),
              )),
              if (mission.produitRef != null)
                Expanded(child: _InfoChip(
                  icon: Icons.translate_outlined,
                  label: mission.produitRef!,
                )),
            ],
          ),
          if (mission.billedStatus != null || mission.clientBilledStatus != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (mission.billedStatus != null)
                  _InfoChip(icon: Icons.receipt_outlined, label: 'Interp: ${mission.billedStatus}'),
                if (mission.clientBilledStatus != null)
                  const SizedBox(width: 8),
                if (mission.clientBilledStatus != null)
                  _InfoChip(icon: Icons.euro_outlined, label: 'Client: ${mission.clientBilledStatus}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

