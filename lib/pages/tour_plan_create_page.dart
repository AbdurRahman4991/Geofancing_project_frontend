import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/location_setting_list_service.dart';
import '../services/tour_plan_service.dart';

class TourPlanCreatePage extends StatefulWidget {
  const TourPlanCreatePage({super.key});
  @override
  State<TourPlanCreatePage> createState() => _TourPlanCreatePageState();
}

class _TourPlanCreatePageState extends State<TourPlanCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final List<Map<String, dynamic>> _geofences = [];
  final List<_StopDraft> _stops = [_StopDraft()];
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadGeofences(); }

  Future<void> _loadGeofences() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      var result = await LocationSettingListService.getGeofences();
      final items = List<dynamic>.from(result['items'] as List);
      final last = result['last_page'] as int? ?? 1;
      for (var page = 2; page <= last; page++) {
        result = await LocationSettingListService.getGeofences(page: page);
        items.addAll(result['items'] as List);
      }
      if (!mounted) return;
      setState(() {
        _geofences
          ..clear()
          ..addAll(items.map((e) => Map<String, dynamic>.from(e as Map)));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Could not load geofences.'; });
    }
  }

  @override
  void dispose() { _notes.dispose(); for (final stop in _stops) { stop.dispose(); } super.dispose(); }

  String _name(Map<String, dynamic> item) => (item['firm_name'] ?? item['company']?['company_name'] ?? 'Geofence ${item['id']}').toString();

  Future<void> _chooseTime(_StopDraft stop) async {
    final selected = await showTimePicker(context: context, initialTime: stop.time ?? const TimeOfDay(hour: 9, minute: 0));
    if (selected != null) setState(() => stop.time = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) throw Exception('Could not find your user ID. Please sign in again.');
      String timeText(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      await TourPlanService.createTourPlan(
        userId: userId,
        planDate: '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        stops: _stops.map((s) => {'geofence_id': int.parse(s.geofenceId!), 'planned_arrival_time': timeText(s.time!), 'notes': s.notes.text.trim().isEmpty ? null : s.notes.text.trim()}).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tour plan created')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create tour plan: $e')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Tour Plan')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_month), title: const Text('Plan date'), subtitle: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'), trailing: const Icon(Icons.edit_calendar), onTap: () async { final date = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (date != null) setState(() => _date = date); }),
      TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Plan notes (optional)', prefixIcon: Icon(Icons.notes), border: OutlineInputBorder()), minLines: 2, maxLines: 3),
      const SizedBox(height: 20),
      Row(children: [Text('Stops', style: Theme.of(context).textTheme.titleLarge), const Spacer(), TextButton.icon(onPressed: () => setState(() => _stops.add(_StopDraft())), icon: const Icon(Icons.add), label: const Text('Add stop'))]),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null)
        Row(children: [
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
          TextButton(onPressed: _loadGeofences, child: const Text('Retry')),
        ]),
      if (!_loading && _error == null && _geofences.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No geofences found. Add a geofence before creating a tour plan.'),
        ),
      for (var i = 0; i < _stops.length; i++) _buildStop(i),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _saving || _loading || _geofences.isEmpty ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save), label: Text(_saving ? 'Saving...' : 'Save tour plan')),
    ])),
  );

  Widget _buildStop(int index) {
    final stop = _stops[index];
    return Card(margin: const EdgeInsets.only(top: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('Stop ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), if (_stops.length > 1) IconButton(onPressed: () => setState(() { _stops.removeAt(index).dispose(); }), icon: const Icon(Icons.delete_outline), tooltip: 'Remove stop')]),
      FormField<String>(
        validator: (_) => stop.geofenceId == null ? 'Select a geofence' : null,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select geofence', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_geofences.isNotEmpty)
              ..._geofences.map((geofence) {
                final id = geofence['id'].toString();
                return RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(_name(geofence)),
                  subtitle: geofence['address'] == null
                      ? null
                      : Text(geofence['address'].toString()),
                  value: id,
                  groupValue: stop.geofenceId,
                  onChanged: (value) {
                    setState(() => stop.geofenceId = value);
                    field.didChange(value);
                  },
                );
              })
            else
              const Text('Geofence list is not available.'),
            if (field.errorText != null)
              Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      FormField<TimeOfDay>(validator: (_) => stop.time == null ? 'Choose an arrival time' : null, builder: (field) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [OutlinedButton.icon(onPressed: () async { await _chooseTime(stop); field.didChange(stop.time); }, icon: const Icon(Icons.schedule), label: Text(stop.time == null ? 'Choose arrival time' : stop.time!.format(context))), if (field.errorText != null) Text(field.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error))])),
      const SizedBox(height: 12),
      TextFormField(controller: stop.notes, decoration: const InputDecoration(labelText: 'Stop notes (optional)', border: OutlineInputBorder()), maxLines: 2),
    ])));
  }
}

class _StopDraft {
  String? geofenceId;
  TimeOfDay? time;
  final notes = TextEditingController();
  void dispose() => notes.dispose();
}
