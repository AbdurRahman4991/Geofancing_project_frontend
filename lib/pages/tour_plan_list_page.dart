import 'package:flutter/material.dart';

import '../services/tour_plan_service.dart';
import 'tour_plan_create_page.dart';

class TourPlanListPage extends StatefulWidget {
  const TourPlanListPage({super.key});
  @override
  State<TourPlanListPage> createState() => _TourPlanListPageState();
}

class _TourPlanListPageState extends State<TourPlanListPage> {
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _plans = [];
  int _page = 1, _lastPage = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(1); _scroll.addListener(_onScroll); }
  void _onScroll() { if (_scroll.hasClients && !_loading && _page < _lastPage && _scroll.position.extentAfter < 300) _load(_page + 1); }
  Future<void> _load(int page) async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try { final result = await TourPlanService.getTourPlans(page: page); if (!mounted) return; setState(() { if (page == 1) _plans.clear(); _plans.addAll(result['items'] as List<Map<String, dynamic>>); _page = result['current_page'] as int; _lastPage = result['last_page'] as int; }); }
    catch (error) { if (mounted) setState(() => _error = error.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _refresh() async { _page = 1; _lastPage = 1; await _load(1); }
  Future<void> _create() async { final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const TourPlanCreatePage())); if (created == true) _refresh(); }
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tour Plans')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Create plan')),
    body: _plans.isEmpty && _loading ? const Center(child: CircularProgressIndicator()) : _error != null && _plans.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Could not load tour plans.'), const SizedBox(height: 8), Text(_error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall), TextButton(onPressed: _refresh, child: const Text('Retry'))]))) : _plans.isEmpty ? RefreshIndicator(onRefresh: _refresh, child: ListView(children: const [SizedBox(height: 180), Center(child: Text('No tour plans yet'))])) : RefreshIndicator(onRefresh: _refresh, child: ListView.builder(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 12, 16, 88), itemCount: _plans.length + (_loading ? 1 : 0), itemBuilder: (context, i) {
      if (i == _plans.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
      final plan = _plans[i];
      final stops = plan['stops'] is List ? (plan['stops'] as List) : <dynamic>[];
      final date = (plan['plan_date'] ?? plan['date'] ?? 'Date not specified').toString();
      return Card(child: ExpansionTile(leading: const CircleAvatar(child: Icon(Icons.route)), title: Text(date), subtitle: Text('${stops.length} ${stops.length == 1 ? 'stop' : 'stops'}${plan['status'] == null ? '' : ' • ${plan['status']}'}'), children: [if ((plan['notes'] ?? '').toString().isNotEmpty) ListTile(dense: true, leading: const Icon(Icons.notes), title: Text(plan['notes'].toString())), for (var s = 0; s < stops.length; s++) _stopTile(stops[s], s)]));
    })),
  );

  Widget _stopTile(dynamic raw, int index) {
    final stop = raw is Map ? raw : <String, dynamic>{};
    final geo = stop['geofence'] is Map ? stop['geofence'] as Map : <dynamic, dynamic>{};
    final title = (geo['firm_name'] ?? stop['firm_name'] ?? stop['geofence_name'] ?? 'Geofence ${stop['geofence_id'] ?? ''}').toString();
    final arrival = (stop['planned_arrival_time'] ?? '').toString();
    final notes = (stop['notes'] ?? '').toString();
    return ListTile(dense: true, leading: CircleAvatar(radius: 14, child: Text('${index + 1}')), title: Text(title), subtitle: Text([if (arrival.isNotEmpty) arrival, if (notes.isNotEmpty) notes].join(' • ')));
  }
}
