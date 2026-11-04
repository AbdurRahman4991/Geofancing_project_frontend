import 'package:flutter/material.dart';

import '../services/location_setting_list_service.dart';
import '../services/order_edit_service.dart';
import '../services/product_service.dart';
import '../widgets/customer_selector.dart';
import '../widgets/product_selector.dart';

class EditOrderPage extends StatefulWidget {
  const EditOrderPage({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerSearchController = TextEditingController();
  final _notesController = TextEditingController();
  final List<Map<String, dynamic>> _geofences = [];
  final List<Map<String, dynamic>> _products = [];
  final Set<String> _selectedProductKeys = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  String? _selectedGeofenceKey;
  String _orderNumber = '';
  String _status = 'pending';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderAndOptions();
  }

  String _productKey(int index) =>
      (_products[index]['id'] ?? _products[index]['product_id'] ?? 'index-$index').toString();

  String _productName(Map<String, dynamic> product) =>
      (product['product_name'] ?? 'Unnamed product').toString();

  String _productLabel(Map<String, dynamic> product) {
    final name = _productName(product);
    final unit = product['unit'] is Map ? product['unit']['short_name'] : null;
    return unit == null || unit.toString().isEmpty ? name : '$name ($unit)';
  }

  String _geofenceKey(int index) =>
      (_geofences[index]['id'] ?? 'index-$index').toString();

  String _geofenceName(Map<String, dynamic> geofence) =>
      (geofence['firm_name'] ?? geofence['company']?['company_name'] ?? 'Geofence')
          .toString();

  int? _toInt(dynamic value) => num.tryParse(value?.toString() ?? '')?.toInt();

  List<Map<String, dynamic>> _asMapList(dynamic value) => value is List
      ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
      : <Map<String, dynamic>>[];

  Future<List<Map<String, dynamic>>> _loadAllProducts() async {
    final firstPage = await ProductService.getProducts(page: 1);
    final products = List<dynamic>.from(firstPage['items'] as List<dynamic>);
    final lastPage = firstPage['last_page'] as int? ?? 1;
    for (var page = 2; page <= lastPage; page++) {
      final result = await ProductService.getProducts(page: page);
      products.addAll(result['items'] as List<dynamic>);
    }
    return products.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> _loadAllGeofences() async {
    final firstPage = await LocationSettingListService.getGeofences(page: 1);
    final locations = List<dynamic>.from(firstPage['items'] as List<dynamic>);
    final lastPage = firstPage['last_page'] as int? ?? 1;
    for (var page = 2; page <= lastPage; page++) {
      final result = await LocationSettingListService.getGeofences(page: page);
      locations.addAll(result['items'] as List<dynamic>);
    }
    return locations.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _loadOrderAndOptions() async {
    try {
      final orderId = _toInt(widget.order['id']);
      if (orderId == null) throw Exception('Order ID is missing');

      final results = await Future.wait([
        OrderEditService.getOrder(orderId),
        _loadAllGeofences(),
        _loadAllProducts(),
      ]);
      final response = results[0] as Map<String, dynamic>;

      dynamic orderData = response['data'];
      if (orderData is Map && orderData['data'] is Map) {
        orderData = orderData['data'];
      }
      final order = orderData is Map
          ? Map<String, dynamic>.from(orderData)
          : widget.order;
      debugPrint('[Order Edit] Loaded: id=${order['id']}, order_number=${order['order_number']}, geofence_id=${order['geofence_id']}, status=${order['status']}');
      final geofences = results[1] as List<Map<String, dynamic>>;
      final products = results[2] as List<Map<String, dynamic>>;
      debugPrint("[Order Edit] Product options loaded: ${products.length}");

      dynamic rawOrderItems = order['items'] ??
          order['order_items'] ??
          order['order_details'] ??
          order['products'];
      if (rawOrderItems is! List || rawOrderItems.isEmpty) {
        rawOrderItems = widget.order['items'] ??
            widget.order['order_items'] ??
            widget.order['products'];
      }
      final selectedIds = <String, int>{};
      final selectedNames = <String, int>{};
      for (final item in _asMapList(rawOrderItems)) {
        final product = item['product'];
        final pivot = item['pivot'];
        debugPrint('[Order Edit] Item: product_id=${item['product_id'] ?? item['productId'] ?? (product is Map ? product['id'] : null)}, quantity=${item['quantity'] ?? item['qty'] ?? (pivot is Map ? pivot['quantity'] : null)}');
        final productId = item['product_id'] ??
            item['productId'] ??
            (product is Map ? product['id'] ?? product['product_id'] : null);
        final quantity = _toInt(item['quantity']) ??
            _toInt(item['qty']) ??
            (pivot is Map ? _toInt(pivot['quantity']) : null) ??
            _toInt(item['ordered_quantity']) ??
            1;
        if (productId != null) selectedIds[productId.toString()] = quantity;
        final productName = item['product_name'] ??
            (product is Map ? product['product_name'] : null);
        if (productName != null) {
          selectedNames[productName.toString().trim().toLowerCase()] = quantity;
        }
      }
      if (!mounted) return;
      setState(() {
        _geofences.addAll(geofences);
        _products.addAll(products);
        final geofence = order['geofence'];
        final geofenceId = order['geofence_id'] ??
            (geofence is Map ? geofence['id'] : null) ??
            widget.order['geofence_id'];
        if (geofenceId != null) {
          final index = _geofences.indexWhere(
            (item) => item['id']?.toString() == geofenceId.toString(),
          );
          if (index >= 0) _selectedGeofenceKey = _geofenceKey(index);
        }
        _orderNumber = (order['order_number'] ?? widget.order['order_number'] ?? '').toString();
        _status = (order['status'] ?? widget.order['status'] ?? 'pending').toString();
        _notesController.text = (order['notes'] ?? '').toString();
        for (var index = 0; index < _products.length; index++) {
          final key = _productKey(index);
          final productId = _products[index]['id'] ?? _products[index]['product_id'];
          final quantity = selectedIds[productId?.toString()] ??
              selectedNames[_productName(_products[index]).trim().toLowerCase()];
          if (quantity != null) {
            _selectedProductKeys.add(key);
            _quantityControllers[key] = TextEditingController(text: quantity.toString());
          } else {
            _quantityControllers[key] = TextEditingController(text: '1');
          }
        }
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

  void _adjustQuantity(String key, int change) {
    final controller = _quantityControllers[key];
    if (controller == null) return;
    final next = ((int.tryParse(controller.text) ?? 1) + change).clamp(1, 999999);
    controller.value = TextEditingValue(
      text: next.toString(),
      selection: TextSelection.collapsed(offset: next.toString().length),
    );
  }

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final geofenceIndex = _geofences.indexWhere(
        (item) => _geofenceKey(_geofences.indexOf(item)) == _selectedGeofenceKey,
      );
      if (geofenceIndex < 0) throw Exception('Select a customer geofence');
      final selectedGeofence = _geofences[geofenceIndex];
      final selectedProducts = _products
          .where((product) => _selectedProductKeys.contains(
              _productKey(_products.indexOf(product))))
          .toList();
      final items = selectedProducts.map((product) {
        final key = _productKey(_products.indexOf(product));
        return {
          'product_id': _toInt(product['id']),
          'quantity': int.parse(_quantityControllers[key]!.text.trim()),
        };
      }).toList();

      await OrderEditService.updateOrder(
        orderId: _toInt(widget.order['id'])!,
        orderNumber: _orderNumber,
        geofenceId: _toInt(selectedGeofence['id'])!,
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: items,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update order: $error')),
      );
    }
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _notesController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Order')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        initialValue: _orderNumber,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Order number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomerSelector(
                        geofences: _geofences,
                        selectedKey: _selectedGeofenceKey,
                        loading: false,
                        error: null,
                        searchController: _customerSearchController,
                        keyFor: _geofenceKey,
                        nameFor: _geofenceName,
                        onChanged: (value) => setState(() => _selectedGeofenceKey = value),
                        onRetry: () {},
                      ),
                      const SizedBox(height: 14),
                      ProductSelector(
                        products: _products,
                        selectedKeys: _selectedProductKeys,
                        quantityControllers: _quantityControllers,
                        loading: false,
                        error: null,
                        keyFor: _productKey,
                        labelFor: _productLabel,
                        onToggle: (index, selected) => setState(() {
                          final key = _productKey(index);
                          if (selected) {
                            _selectedProductKeys.add(key);
                          } else {
                            _selectedProductKeys.remove(key);
                          }
                        }),
                        onAdjustQuantity: _adjustQuantity,
                        onRetry: () {},
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: [
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'approved', child: Text('Approved')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          if (!['pending', 'approved', 'completed', 'cancelled'].contains(_status))
                            DropdownMenuItem(value: _status, child: Text(_status)),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                        minLines: 3,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _updateOrder,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Updating...' : 'Update Order'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
