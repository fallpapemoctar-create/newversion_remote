import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
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
  bool _cardsView = true;
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

  int get _validatedCount =>
      _missions.where((m) => m.missionStatus == 1 || m.missionStatus == 2).length;
  int get _finishedCount => _missions.where((m) => m.missionStatus == 3).length;
  int get _cancelledCount => _missions.where((m) => m.missionStatus == 9).length;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        widget.interpreteNom != null
                            ? 'Missions — ${widget.interpreteNom}'
                            : 'Missions',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_total mission(s) au total',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (widget.interpreteId == null) ...[
                  IconButton(
                    icon: Icon(
                      _cardsView ? Icons.table_rows_outlined : Icons.grid_view_outlined,
                    ),
                    onPressed: () => setState(() => _cardsView = !_cardsView),
                    tooltip: _cardsView ? 'Vue tableau' : 'Vue cartes',
                  ),
                  const SizedBox(width: 4),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list_outlined),
                        onPressed: () => setState(() => _showFilters = !_showFilters),
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
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: _load,
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
          ),

          if (widget.interpreteId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.assignment_outlined,
                      iconColor: AppTheme.primary,
                      iconBg: AppTheme.primary.withValues(alpha: 0.1),
                      value: '$_total',
                      label: 'Total',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.verified_outlined,
                      iconColor: AppTheme.success,
                      iconBg: AppTheme.success.withValues(alpha: 0.1),
                      value: '$_validatedCount',
                      label: 'Validées',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.check_circle_outline,
                      iconColor: AppTheme.success,
                      iconBg: AppTheme.success.withValues(alpha: 0.1),
                      value: '$_finishedCount',
                      label: 'Terminées',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.cancel_outlined,
                      iconColor: AppTheme.danger,
                      iconBg: AppTheme.danger.withValues(alpha: 0.1),
                      value: '$_cancelledCount',
                      label: 'Annulées',
                    ),
                  ),
                ],
              ),
            ),

          if (widget.interpreteId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher une mission, un interprète...',
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
                  filled: true,
                  fillColor: AppTheme.surface,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _load(),
              ),
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
                            decoration: const InputDecoration(
                              labelText: 'Date début',
                              hintText: 'YYYY-MM-DD',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _dateEndCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Date fin',
                              hintText: 'YYYY-MM-DD',
                              isDense: true,
                            ),
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
                            child: _cardsView
                                ? ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _missions.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                                    itemBuilder: (_, i) => _MissionCard(
                                      mission: _missions[i],
                                      formatDate: _formatDate,
                                    ),
                                  )
                                : _MissionsTable(
                                    missions: _missions,
                                    formatDate: _formatDate,
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
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

class _MissionCard extends StatelessWidget {
  final MissionModel mission;
  final String Function(String?) formatDate;

  const _MissionCard({required this.mission, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final statusColors = <int, Color>{
      0: Colors.orange,
      1: Colors.blue,
      2: AppTheme.primary,
      3: AppTheme.success,
      9: AppTheme.danger,
    };
    final color = statusColors[mission.missionStatus] ?? AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
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
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mission.statusLabel,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
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

class _MissionsTable extends StatelessWidget {
  final List<MissionModel> missions;
  final String Function(String?) formatDate;

  const _MissionsTable({required this.missions, required this.formatDate});

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return AppTheme.warning;
      case 1:
        return Colors.blue;
      case 2:
        return AppTheme.primary;
      case 3:
        return AppTheme.success;
      case 9:
        return AppTheme.danger;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              columns: const [
                DataColumn(label: Text('Référence')),
                DataColumn(label: Text('Interprète')),
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Statut')),
              ],
              rows: missions.map((m) {
                final color = _statusColor(m.missionStatus);
                final ref = m.referenceDevis.isNotEmpty ? m.referenceDevis : 'Mission #${m.id}';
                return DataRow(
                  cells: [
                    DataCell(Text(ref)),
                    DataCell(Text(m.interpreteName.trim().isEmpty ? '—' : m.interpreteName)),
                    DataCell(Text((m.clientName ?? '').isEmpty ? '—' : m.clientName!)),
                    DataCell(Text(formatDate(m.dateMission ?? m.debutMission))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          m.statusLabel,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
