import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_setting_list_service.dart';
import '../pages/location_setting.dart';

class LocationSettingList extends StatefulWidget {
  const LocationSettingList({super.key});
  @override
  State<LocationSettingList> createState() => _LocationSettingListState();
}

class _LocationSettingListState extends State<LocationSettingList> {
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _locations = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  bool _hasError = false;
  bool get _hasMore => _currentPage < _lastPage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(1);
    checkAuth();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if ((token == null || token.isEmpty) && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;
    if (_scrollController.position.extentAfter < 300) _loadPage(_currentPage + 1);
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading || (page > 1 && !_hasMore)) return;
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final result = await LocationSettingListService.getGeofences(page: page);
      if (!mounted) return;
      setState(() {
        if (page == 1) _locations.clear();
        _locations.addAll(result['items'] as List<dynamic>);
        _currentPage = result['current_page'] as int;
        _lastPage = result['last_page'] as int;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reload() async {
    _currentPage = 1;
    _lastPage = 1;
    await _loadPage(1);
  }

  Future<void> _openGeofence({Map<String, dynamic>? geofence}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GeofenceMapPage(geofence: geofence)),
    );
    if (result == true) await _reload();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Settings')),
      body: _locations.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError && _locations.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Could not load locations.'),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ]))
              : _locations.isEmpty
                  ? const Center(child: Text('No Location Found'))
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _locations.length + (_hasMore || _isLoading || _hasError ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _locations.length) {
                            if (_hasError) {
                              return Center(child: TextButton(
                              onPressed: () => _loadPage(_currentPage + 1),
                              child: const Text('Could not load more. Tap to retry'),
                            ));
                            }
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final item = _locations[index] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.location_on)),
                              title: Text(item['company']?['company_name'] ?? ' ',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Firm: ${item['firm_name'] ?? '-'}'),
                                  Text('Latitude : ${item['latitude'] ?? '-'}'),
                                  Text('Longitude : ${item['longitude'] ?? '-'}'),
                                  Text('Radius : ${item['radius'] ?? '-'} m'),
                                  Text('Visited : ${item['checked'] ?? '-'}'),
                                ]),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) { if (value == 'edit') _openGeofence(geofence: item); },
                                itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Edit'))],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openGeofence(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
