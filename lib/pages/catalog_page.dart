import 'package:flutter/material.dart';

import '../services/catalog_service.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await CatalogService.getCatalog(page: page);
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(result['items'] as List);
        _currentPage = result['current_page'] as int? ?? page;
        _lastPage = result['last_page'] as int? ?? page;
        _total = result['total'] as int? ?? _items.length;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _value(dynamic value, {String fallback = '—'}) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          IconButton(
            tooltip: 'Refresh catalog',
            onPressed: _loading ? null : () => _loadCatalog(page: _currentPage),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_outlined, size: 48, color: colors.error),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _loadCatalog(page: _currentPage),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? const Center(child: Text('No catalog items found.'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: colors.primary),
                              const SizedBox(width: 10),
                              Text('$_total ${_total == 1 ? 'item' : 'items'}',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const Spacer(),
                              Text('Page $_currentPage of $_lastPage'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Card(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: colors.primaryContainer,
                                        foregroundColor: colors.onPrimaryContainer,
                                        child: const Icon(Icons.inventory_2_outlined),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _value(item['product_name'], fallback: 'Unnamed product'),
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 16,
                                              runSpacing: 6,
                                              children: [
                                                _InfoLabel(icon: Icons.sell_outlined,
                                                    text: '৳ ${_value(item['price'])}'),
                                                _InfoLabel(icon: Icons.warehouse_outlined,
                                                    text: 'Stock: ${_value(item['stock'])}'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_lastPage > 1)
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _currentPage > 1
                                        ? () => _loadCatalog(page: _currentPage - 1)
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                    label: const Text('Previous'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _currentPage < _lastPage
                                        ? () => _loadCatalog(page: _currentPage + 1)
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                    label: const Text('Next'),
                                    iconAlignment: IconAlignment.end,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}
