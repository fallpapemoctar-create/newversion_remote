import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_chip.dart';
import 'models/invoice_model.dart';
import 'services/facturation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FacturationScreen
// Reproduit la maquette Figma : KPI cards · recherche · filtres · liste paginée
// ─────────────────────────────────────────────────────────────────────────────

class FacturationScreen extends StatefulWidget {
  const FacturationScreen({super.key});

  @override
  State<FacturationScreen> createState() => _FacturationScreenState();
}

class _FacturationScreenState extends State<FacturationScreen> {
  final _service = FacturationService();
  final _searchCtrl = TextEditingController();

  List<InvoiceModel> _invoices = [];
  int _total = 0;
  bool _loading = false;
  String? _error;

  // Filters
  bool _showFilters = false;
  String _filterStatus = 'all';
  final _dateStartCtrl = TextEditingController();
  final _dateEndCtrl = TextEditingController();
  final _amountMinCtrl = TextEditingController();
  final _amountMaxCtrl = TextEditingController();

  // Pagination
  int _page = 1;
  static const _pageSize = 30;

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
    _amountMinCtrl.dispose();
    _amountMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getInvoices(
        page: _page,
        pageSize: _pageSize,
        q: _searchCtrl.text,
        status: _filterStatus,
        dateStart: _dateStartCtrl.text,
        dateEnd: _dateEndCtrl.text,
        amountMin: _amountMinCtrl.text,
        amountMax: _amountMaxCtrl.text,
      );
      setState(() {
        _invoices = result['invoices'] as List<InvoiceModel>;
        _total = result['total'] as int;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _resetFilters() {
    _searchCtrl.clear();
    _dateStartCtrl.clear();
    _dateEndCtrl.clear();
    _amountMinCtrl.clear();
    _amountMaxCtrl.clear();
    setState(() {
      _filterStatus = 'all';
      _page = 1;
    });
    _load();
  }

  void _search() {
    setState(() => _page = 1);
    _load();
  }

  int get _totalPages => (_total / _pageSize).ceil().clamp(1, 999999);

  // KPI computed from current page data
  int get _paidCount => _invoices.where((i) => i.fkStatut == 2).length;
  double get _paidAmount =>
      _invoices.where((i) => i.fkStatut == 2).fold(0.0, (s, i) => s + i.totalTTC);
  double get _pendingAmount =>
      _invoices.where((i) => i.fkStatut == 1).fold(0.0, (s, i) => s + i.totalTTC);

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
                            'Facturation',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_total facture${_total > 1 ? 's' : ''} · Gérez et suivez vos factures clients',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      onPressed: _showCreateDraftDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Créer une facture', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      hintText: 'Rechercher par référence, client…',
                      prefixIcon: const Icon(Icons.search, size: 24, color: AppTheme.textMuted),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                _search();
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _search(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _buildKpiRow(),
          ),

          // ── Filters panel ─────────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                _showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: _buildFiltersPanel(),
            secondChild: const SizedBox.shrink(),
          ),

          // ── Actions row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.table_chart,
                  label: 'Excel',
                  color: AppTheme.success,
                    onTap: _exportCsv,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.download,
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

          // ── Content ───────────────────────────────────────────────────────
          Expanded(child: _buildContent()),

          // ── Pagination ────────────────────────────────────────────────────
          if (!_loading && _total > _pageSize) _buildPagination(),
        ],
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterStatus != 'all') count++;
    if (_dateStartCtrl.text.isNotEmpty) count++;
    if (_dateEndCtrl.text.isNotEmpty) count++;
    if (_amountMinCtrl.text.isNotEmpty) count++;
    if (_amountMaxCtrl.text.isNotEmpty) count++;
    return count;
  }

  Future<void> _exportCsv() async {
    final rows = <String>[
      'Reference;Client;Total HT;Total TTC;Statut;Date',
      ..._invoices.map(
        (i) => '${i.ref};${i.clientName};${i.totalHT.toStringAsFixed(2)};${i.totalTTC.toStringAsFixed(2)};${i.statusLabel};${i.date ?? ''}',
      ),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export CSV copie (${_invoices.length} lignes).')),
    );
  }

  Future<void> _showCreateDraftDialog() async {
    final clientCtrl = TextEditingController();
    final monthCtrl = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
    );
    final totalCtrl = TextEditingController(text: '0');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Creer un brouillon de facture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client')),
            const SizedBox(height: 10),
            TextField(controller: monthCtrl, decoration: const InputDecoration(labelText: 'Mois (YYYY-MM)')),
            const SizedBox(height: 10),
            TextField(
              controller: totalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total HT'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final client = clientCtrl.text.trim();
              final month = monthCtrl.text.trim();
              final total = double.tryParse(totalCtrl.text.trim()) ?? 0;
              if (client.isEmpty || month.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client et mois sont obligatoires.')),
                );
                return;
              }
              try {
                await _service.createDraft(clientName: client, month: month, totalHt: total);
                if (!ctx.mounted) return;
                Navigator.pop(ctx, true);
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                );
              }
            },
            child: const Text('Creer'),
          ),
        ],
      ),
    );

    if (created == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brouillon cree avec succes.')),
      );
    }
  }

  // ── KPI row ────────────────────────────────────────────────────────────────
  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.receipt_long,
            iconBg: AppTheme.primary.withValues(alpha: 0.1),
            iconColor: AppTheme.primary,
            value: _total.toString(),
            label: 'Total',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icon: Icons.check_circle_outline,
            iconBg: AppTheme.success.withValues(alpha: 0.1),
            iconColor: AppTheme.success,
            value: _paidCount.toString(),
            label: 'Payées',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icon: Icons.trending_up,
            iconBg: AppTheme.success.withValues(alpha: 0.1),
            iconColor: AppTheme.success,
            value: '${_paidAmount.toStringAsFixed(0)} €',
            label: 'Encaissé',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icon: Icons.euro,
            iconBg: AppTheme.warning.withValues(alpha: 0.1),
            iconColor: AppTheme.warning,
            value: '${_pendingAmount.toStringAsFixed(0)} €',
            label: 'En attente',
          ),
        ),
      ],
    );
  }

  // ── Filters panel ──────────────────────────────────────────────────────────
  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtres avancés',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réinitialiser'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _filterStatus,
            decoration: const InputDecoration(labelText: 'Statut', isDense: true),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
              DropdownMenuItem(value: '0', child: Text('Brouillon')),
              DropdownMenuItem(value: '1', child: Text('Envoyée')),
              DropdownMenuItem(value: '2', child: Text('Payée')),
              DropdownMenuItem(value: '3', child: Text('Abandonnée')),
            ],
            onChanged: (v) {
              setState(() {
                _filterStatus = v ?? 'all';
                _page = 1;
              });
              _load();
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
                      setState(() {
                        _dateStartCtrl.text =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      });
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
                      setState(() {
                        _dateEndCtrl.text =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountMinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Montant min (€)',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountMaxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Montant max (€)',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _search(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _search,
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
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────
  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
              const SizedBox(height: 12),
              const Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_invoices.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Aucune facture trouvée',
        subtitle: 'Modifiez vos filtres ou créez une nouvelle facture.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: _invoices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _InvoiceCard(invoice: _invoices[i]),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () {
                    setState(() => _page--);
                    _load();
                  }
                : null,
          ),
          Text(
            '$_page / $_totalPages',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < _totalPages
                ? () {
                    setState(() => _page++);
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _KpiCard
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
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

// ─────────────────────────────────────────────────────────────────────────────
// _InvoiceCard
// ─────────────────────────────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    // Couleurs remplacées par StatusChip sémantique

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                      invoice.ref.isNotEmpty ? invoice.ref : '#${invoice.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.clientName.isNotEmpty ? invoice.clientName : '—',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${invoice.totalTTC.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusChip.fromString(invoice.statusLabel),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (invoice.date != null) ...[
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  invoice.date!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
              const Spacer(),
              Text(
                'HT : ${invoice.totalHT.toStringAsFixed(2)} €',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionBtn
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
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
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

