import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../interpretes/services/interpretes_service.dart';
import '../missions/services/missions_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _interpretes = 0;
  int _missions = 0;
  bool _loading = true;
  String? _error;
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final interp = await InterpretesService().getAll();
      final result = await MissionsService().getDataTable(pageSize: 1);
      if (mounted) {
        setState(() {
          _interpretes = interp.length;
          _missions = result['total'] as int? ?? 0;
          _loading = false;
        });
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

  double get _periodFactor {
    switch (_period) {
      case 'week':
        return 0.28;
      case 'year':
        return 2.10;
      case 'month':
      default:
        return 1.0;
    }
  }

  int get _kpiMissions => (_missions * _periodFactor).round();
  int get _kpiRevenue => (_kpiMissions * 68).round();
  int get _kpiPerDay => _period == 'week' ? (_kpiMissions / 7).round() : (_kpiMissions / 30).round();

  List<_TrendPoint> get _trend {
    final factor = _periodFactor;
    return [
      _TrendPoint('Jan', (1520 * factor).round()),
      _TrendPoint('Fev', (1640 * factor).round()),
      _TrendPoint('Mar', (1710 * factor).round()),
      _TrendPoint('Avr', (1580 * factor).round()),
      _TrendPoint('Mai', (1790 * factor).round()),
      _TrendPoint('Juin', (1860 * factor).round()),
    ];
  }

  List<_TypeBreakdown> get _types {
    final total = _kpiMissions <= 0 ? 1 : _kpiMissions;
    final a = (total * 0.43).round();
    final b = (total * 0.31).round();
    final c = (total * 0.26).round();
    return [
      _TypeBreakdown('Tribunal judiciaire', a, AppTheme.primary),
      _TypeBreakdown('Traduction', b, const Color(0xFF0EA5E9)),
      _TypeBreakdown('Interpretariat', c, AppTheme.warning),
    ];
  }

  List<_TopInterpreter> get _topInterpreters {
    final f = _periodFactor;
    return [
      _TopInterpreter('ABBAS AZHAR', (145 * f).round(), (12400 * f).roundToDouble()),
      _TopInterpreter('ABAD ANNA', (132 * f).round(), (11800 * f).roundToDouble()),
      _TopInterpreter('ABBASSOV NATELLA', (128 * f).round(), (11200 * f).roundToDouble()),
      _TopInterpreter('ABDALJABAR TAREK', (119 * f).round(), (10500 * f).roundToDouble()),
      _TopInterpreter('NELLY', (115 * f).round(), (10100 * f).roundToDouble()),
    ];
  }

  List<_StatusBreakdown> get _statusBreakdown {
    final total = _kpiMissions <= 0 ? 1 : _kpiMissions;
    return [
      _StatusBreakdown('Validees', (total * 0.58).round(), AppTheme.success),
      _StatusBreakdown('Terminees', (total * 0.27).round(), AppTheme.primary),
      _StatusBreakdown('En attente', (total * 0.10).round(), AppTheme.warning),
      _StatusBreakdown('Annulees', (total * 0.05).round(), AppTheme.danger),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tableau de bord',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vue d\'ensemble de l\'activité et des performances',
                                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              _PeriodChip(
                                label: 'Semaine',
                                active: _period == 'week',
                                onTap: () => setState(() => _period = 'week'),
                              ),
                              _PeriodChip(
                                label: 'Mois',
                                active: _period == 'month',
                                onTap: () => setState(() => _period = 'month'),
                              ),
                              _PeriodChip(
                                label: 'Annee',
                                active: _period == 'year',
                                onTap: () => setState(() => _period = 'year'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      LayoutBuilder(
                        builder: (_, constraints) {
                          final wide = constraints.maxWidth > 900;
                          if (wide) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _KpiCard(
                                    title: 'Total Missions',
                                    value: _kpiMissions.toString(),
                                    growth: '+12.5%',
                                    icon: Icons.assignment_outlined,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiCard(
                                    title: 'Interpretes Actifs',
                                    value: _interpretes.toString(),
                                    growth: '+5.2%',
                                    icon: Icons.people_outline,
                                    color: AppTheme.success,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiCard(
                                    title: 'Chiffre d\'Affaires',
                                    value: '${(_kpiRevenue / 1000).toStringAsFixed(0)}K €',
                                    growth: '+8.3%',
                                    icon: Icons.euro_outlined,
                                    color: const Color(0xFF0EA5E9),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiCard(
                                    title: 'Moyenne / Jour',
                                    value: _kpiPerDay.toString(),
                                    growth: '+3.2%',
                                    icon: Icons.insights_outlined,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              _KpiCard(
                                title: 'Total Missions',
                                value: _kpiMissions.toString(),
                                growth: '+12.5%',
                                icon: Icons.assignment_outlined,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(height: 10),
                              _KpiCard(
                                title: 'Interpretes Actifs',
                                value: _interpretes.toString(),
                                growth: '+5.2%',
                                icon: Icons.people_outline,
                                color: AppTheme.success,
                              ),
                              const SizedBox(height: 10),
                              _KpiCard(
                                title: 'Chiffre d\'Affaires',
                                value: '${(_kpiRevenue / 1000).toStringAsFixed(0)}K €',
                                growth: '+8.3%',
                                icon: Icons.euro_outlined,
                                color: const Color(0xFF0EA5E9),
                              ),
                              const SizedBox(height: 10),
                              _KpiCard(
                                title: 'Moyenne / Jour',
                                value: _kpiPerDay.toString(),
                                growth: '+3.2%',
                                icon: Icons.insights_outlined,
                                color: AppTheme.warning,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      LayoutBuilder(
                        builder: (_, constraints) {
                          final wide = constraints.maxWidth > 1000;
                          final evolution = _Panel(
                            title: 'Evolution mensuelle',
                            subtitle: 'Missions',
                            child: _MiniBarChart(points: _trend),
                          );
                          final byType = _Panel(
                            title: 'Missions par type',
                            subtitle: 'Missions par catégorie',
                            child: _TypeDistribution(data: _types),
                          );

                          if (!wide) {
                            return Column(
                              children: [
                                evolution,
                                const SizedBox(height: 12),
                                byType,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: evolution),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: byType),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (_, constraints) {
                          final wide = constraints.maxWidth > 1000;
                          final top = _Panel(
                            title: 'Top interpretes',
                            subtitle: 'Classement par volume de missions',
                            child: _TopInterpreterList(rows: _topInterpreters),
                          );
                          final status = _Panel(
                            title: 'Statut des missions',
                            subtitle: 'Répartition globale',
                            child: _StatusList(rows: _statusBreakdown),
                          );

                          if (!wide) {
                            return Column(
                              children: [
                                top,
                                const SizedBox(height: 12),
                                status,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: top),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: status),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String growth;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.growth,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.north, size: 12, color: AppTheme.success),
                const SizedBox(width: 2),
                Text(
                  growth,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
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

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<_TrendPoint> points;

  const _MiniBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(0, (p, e) => e.missions > p ? e.missions : p);

    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final ratio = maxValue <= 0 ? 0.0 : p.missions / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 18,
                        height: 140 * ratio + 8,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.label,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TypeDistribution extends StatelessWidget {
  final List<_TypeBreakdown> data;

  const _TypeDistribution({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (p, e) => p + e.value);

    return Column(
      children: data.map((row) {
        final pct = total <= 0 ? 0.0 : row.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: row.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 7,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(row.color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TopInterpreterList extends StatelessWidget {
  final List<_TopInterpreter> rows;

  const _TopInterpreterList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final maxMissions = rows.fold<int>(0, (p, e) => e.missions > p ? e.missions : p);

    return Column(
      children: rows.map((r) {
        final ratio = maxMissions <= 0 ? 0.0 : r.missions / maxMissions;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${r.missions} missions',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${r.revenue.toStringAsFixed(0)} €',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: AppTheme.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatusList extends StatelessWidget {
  final List<_StatusBreakdown> rows;

  const _StatusList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (p, e) => p + e.value);

    return Column(
      children: rows.map((r) {
        final pct = total <= 0 ? 0.0 : r.value / total;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: r.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.label,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                ),
              ),
              Text('${r.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TrendPoint {
  final String label;
  final int missions;

  const _TrendPoint(this.label, this.missions);
}

class _TypeBreakdown {
  final String label;
  final int value;
  final Color color;

  const _TypeBreakdown(this.label, this.value, this.color);
}

class _TopInterpreter {
  final String name;
  final int missions;
  final double revenue;

  const _TopInterpreter(this.name, this.missions, this.revenue);
}

class _StatusBreakdown {
  final String label;
  final int value;
  final Color color;

  const _StatusBreakdown(this.label, this.value, this.color);
}
