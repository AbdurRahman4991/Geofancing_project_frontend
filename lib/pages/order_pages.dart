import 'package:flutter/material.dart';

import '../services/order_service.dart';
import 'edit_order_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasError = false;
  int _currentPage = 1;
  int _lastPage = 1;

  bool get _hasMore => _currentPage < _lastPage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadOrders(refresh: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) {
      return;
    }
    if (_scrollController.position.extentAfter < 250) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    if (_loadingMore || (_loading && !refresh)) return;
    final page = refresh ? 1 : _currentPage + 1;
    setState(() {
      if (refresh) {
        _loading = true;
        _hasError = false;
        _orders.clear();
        _currentPage = 1;
        _lastPage = 1;
      } else {
        _loadingMore = true;
        _hasError = false;
      }
    });

    try {
      final result = await OrderService.getOrders(page: page);
      if (!mounted) return;
      setState(() {
        if (refresh) _orders.clear();
        _orders.addAll(result['items'] as List<Map<String, dynamic>>);
        _currentPage = result['current_page'] as int? ?? page;
        _lastPage = result['last_page'] as int? ?? _currentPage;
        _loading = false;
        _loadingMore = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _hasError = true;
      });
    }
  }

  Future<void> _openCreateOrder() async {
    final created = await Navigator.pushNamed(context, '/order-create');
    if (created == true) _loadOrders(refresh: true);
  }

  Future<void> _openEditOrder(Map<String, dynamic> order) async {
    final debugItems = _itemsFor(order).map((item) {
      final product = item['product'];
      return {
        'product_id': item['product_id'] ?? (product is Map ? product['id'] : null),
        'product_name': item['product_name'] ??
            (product is Map ? product['product_name'] : null),
        'quantity': item['quantity'] ?? item['qty'] ??
            (item['pivot'] is Map ? item['pivot']['quantity'] : null),
      };
    }).toList();
    debugPrint('[Order Edit] Clicked: id=${order['id']}, '
        'order_number=${order['order_number']}, '
        'geofence_id=${order['geofence_id'] ?? (order['geofence'] is Map ? order['geofence']['id'] : null)}, '
        'status=${order['status']}');
    debugPrint('[Order Edit] Items: $debugItems');
    final orderId = int.tryParse(order['id']?.toString() ?? '');
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit this order: order ID is missing.')),
      );
      return;
    }
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditOrderPage(order: order)),
    );
    if (updated == true) _loadOrders(refresh: true);
  }
  List<Map<String, dynamic>> _itemsFor(Map<String, dynamic> order) {
    final rawItems = order['items'] ?? order['order_items'] ?? order['products'];
    if (rawItems is! List) return [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  num? _asNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  num? _unitPrice(Map<String, dynamic> item) {
    final product = item['product'];
    return _asNumber(
      item['unit_price'] ??
          item['price'] ??
          item['selling_price'] ??
          (product is Map ? product['unit_price'] ?? product['price'] : null),
    );
  }

  num? _lineTotal(Map<String, dynamic> item) {
    final existingTotal = _asNumber(
      item['line_total'] ?? item['subtotal'] ?? item['total'],
    );
    if (existingTotal != null) return existingTotal;
    final unitPrice = _unitPrice(item);
    final quantity = _asNumber(item['quantity']);
    if (unitPrice == null || quantity == null) return null;
    return unitPrice * quantity;
  }

  num? _orderTotal(Map<String, dynamic> order, List<Map<String, dynamic>> items) {
    final total = _asNumber(
      order['grand_total'] ?? order['total_amount'] ?? order['total'],
    );
    if (total != null) return total;
    if (items.isEmpty) return null;
    final lineTotals = items.map(_lineTotal).toList();
    if (lineTotals.any((value) => value == null)) return null;
    return lineTotals.fold<num>(0, (sum, value) => sum + value!);
  }

  String _money(num? value) => value == null ? 'Ã¯Â¿Â½' : value.toStringAsFixed(2);

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = _itemsFor(order);
    final orderNumber = order['order_number']?.toString() ?? 'Order';
    final customer = order['geofence'] is Map
        ? (order['geofence']['firm_name']?.toString() ?? 'Customer')
        : (order['customer']?.toString() ?? 'Customer');
    final createdAt = order['created_at']?.toString() ??
        order['createdAt']?.toString() ??
        '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.shopping_bag_outlined),
              ),
              title: Text(orderNumber),
              subtitle: Text('$customer${createdAt.isEmpty ? '' : '\n$createdAt'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (order['status'] != null)
                    Chip(label: Text(order['status'].toString())),
                  IconButton(
                    tooltip: 'Edit order',
                    onPressed: () => _openEditOrder(order),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (items.isEmpty)
              const Text('No order items returned by the server.')
            else
              for (final item in items) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['product_name'] ??
                                (item['product'] is Map
                                    ? item['product']['product_name']
                                    : null) ??
                                'Product')
                            .toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Qty: ${item['quantity'] ?? 'Ã¯Â¿Â½'}  Ã¯Â¿Â½  Unit price: ${_money(_unitPrice(item))}  Ã¯Â¿Â½  Total: ${_money(_lineTotal(item))}',
                      ),
                    ],
                  ),
                ),
              ],
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Order total: ${_money(_orderTotal(order, items))}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order List')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateOrder,
        icon: const Icon(Icons.add),
        label: const Text('Create Order'),
      ),
      body: _loading && _orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _hasError && _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load orders.'),
                      TextButton(
                        onPressed: () => _loadOrders(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : RefreshIndicator(
                      onRefresh: () => _loadOrders(refresh: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _orders.length + (_hasMore || _loadingMore || _hasError ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _orders.length) {
                            return _buildOrderCard(_orders[index]);
                          }
                          if (_loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (_hasError) {
                            return Center(
                              child: TextButton(
                                onPressed: _loadOrders,
                                child: const Text('Could not load more. Tap to retry.'),
                              ),
                            );
                          }
                          return const SizedBox(height: 48);
                        },
                      ),
                    ),
    );
  }
}
