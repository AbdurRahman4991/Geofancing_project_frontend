import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_setting_list_service.dart';
import '../services/product_service.dart';
import '../services/create_order_service.dart';
import '../widgets/customer_selector.dart';
import '../widgets/product_selector.dart';

const _ordersKey = 'local_orders';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _geofences = [];
  String? _selectedGeofenceKey;
  bool _loadingGeofences = true;
  String? _geofenceError;
  final List<Map<String, dynamic>> _products = [];
  final Set<String> _selectedProductKeys = {};
  final Map<String, TextEditingController> _productQuantityControllers = {};
  bool _loadingProducts = true;
  String? _productError;
  final _notesController = TextEditingController();
  final _geofenceSearchController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadGeofences();
    _loadProducts();
  }

  String _productKey(int index) =>
      (_products[index]['id'] ?? 'index-$index').toString();

  String _productName(Map<String, dynamic> product) =>
      (product['product_name'] ?? 'Unnamed product').toString();

  String _productLabel(Map<String, dynamic> product) {
    final name = _productName(product);
    final unit = product['unit']?['short_name'];
    return unit == null || unit.toString().isEmpty ? name : '$name ($unit)';
  }

  void _adjustQuantity(String productKey, int change) {
    final controller = _productQuantityControllers[productKey];
    if (controller == null) return;

    final current = int.tryParse(controller.text) ?? 1;
    final next = (current + change).clamp(1, 999999);
    final value = next.toString();
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _loadProducts() async {
    try {
      final firstPage = await ProductService.getProducts(page: 1);
      final products = List<dynamic>.from(firstPage['items'] as List<dynamic>);
      final lastPage = firstPage['last_page'] as int? ?? 1;
      for (var page = 2; page <= lastPage; page++) {
        final result = await ProductService.getProducts(page: page);
        products.addAll(result['items'] as List<dynamic>);
      }
      if (!mounted) return;
      setState(() {
        _products
          ..clear()
          ..addAll(products.map((item) => Map<String, dynamic>.from(item as Map)));
        for (var index = 0; index < _products.length; index++) {
          _productQuantityControllers[_productKey(index)] =
              TextEditingController(text: '1');
        }
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {

        _loadingProducts = false;
        _productError = 'Could not load the product list.';
      });
    }
  }

  String _geofenceKey(int index) =>
      (_geofences[index]['id'] ?? 'index-$index').toString();

  String _geofenceName(Map<String, dynamic> geofence) =>
      (geofence['firm_name'] ?? geofence['company']?['company_name'] ?? 'Geofence')
          .toString();

  Future<void> _loadGeofences() async {
    try {
      final firstPage = await LocationSettingListService.getGeofences(page: 1);
      final locations = List<dynamic>.from(firstPage['items'] as List<dynamic>);
      final lastPage = firstPage['last_page'] as int? ?? 1;
      for (var page = 2; page <= lastPage; page++) {
        final result = await LocationSettingListService.getGeofences(page: page);
        locations.addAll(result['items'] as List<dynamic>);
      }
      if (!mounted) return;
      setState(() {
        _geofences
          ..clear()
          ..addAll(locations.map((item) => Map<String, dynamic>.from(item as Map)));
        _loadingGeofences = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingGeofences = false;
        _geofenceError = 'Could not load your geofence list.';
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _productQuantityControllers.values) {
      controller.dispose();
    }
    _notesController.dispose();
    _geofenceSearchController.dispose();
    super.dispose();
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final selectedGeofence = _geofences.firstWhere(
        (item) => _geofenceKey(_geofences.indexOf(item)) == _selectedGeofenceKey,
      );
      final selectedProducts = _products
          .where((product) => _selectedProductKeys.contains(
              _productKey(_products.indexOf(product))))
          .toList();
      final orderProducts = selectedProducts.map((product) {
        final key = _productKey(_products.indexOf(product));
        return {
          'product_id': int.parse(product['id'].toString()),
          'product_name': _productName(product),
          'quantity': int.parse(_productQuantityControllers[key]!.text.trim()),
        };
      }).toList();

      final now = DateTime.now();
      final orderNumber = 'ORD-${now.year}-${now.millisecondsSinceEpoch}';
      final notes = _notesController.text.trim();
      final response = await CreateOrderService.createOrder(
        orderNumber: orderNumber,
        geofenceId: int.parse(selectedGeofence['id'].toString()),
        status: 'pending',
        notes: notes.isEmpty ? null : notes,
        items: orderProducts
            .map((product) => {
                  'product_id': product['product_id'],
                  'quantity': product['quantity'],
                })
            .toList(),
      );

      final prefs = await SharedPreferences.getInstance();
      final rawOrders = prefs.getString(_ordersKey);
      final orders = rawOrders == null
          ? <dynamic>[]
          : jsonDecode(rawOrders) as List<dynamic>;
      orders.add({
        'order_number': orderNumber,
        'customer': _geofenceName(selectedGeofence),
        'geofence_id': selectedGeofence['id'],
        'product': selectedProducts.map(_productName).join(', '),
        'product_ids': selectedProducts.map((product) => product['id']).toList(),
        'products': orderProducts,
        'quantity': orderProducts.fold<int>(
          0,
          (total, product) => total + (product['quantity'] as int),
        ),
        'notes': notes,
        'createdAt': now.toIso8601String().substring(0, 16).replaceFirst('T', ' '),
        'api_response': response,
      });
      await prefs.setString(_ordersKey, jsonEncode(orders));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create order: $error')),
      );
    }
  }
  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomerSelector(
              geofences: _geofences,
              selectedKey: _selectedGeofenceKey,
              loading: _loadingGeofences,
              error: _geofenceError,
              searchController: _geofenceSearchController,
              keyFor: _geofenceKey,
              nameFor: _geofenceName,
              onChanged: (value) => setState(() => _selectedGeofenceKey = value),
              onRetry: () {
                setState(() {
                  _loadingGeofences = true;
                  _geofenceError = null;
                });
                _loadGeofences();
              },
            ),
            const SizedBox(height: 14),
            ProductSelector(
              products: _products,
              selectedKeys: _selectedProductKeys,
              quantityControllers: _productQuantityControllers,
              loading: _loadingProducts,
              error: _productError,
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
              onRetry: () {
                setState(() {
                  _loadingProducts = true;
                  _productError = null;
                });
                _loadProducts();
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              decoration: _decoration('Notes (optional)', Icons.notes),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _saveOrder,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Order'),
            ),
          ],
        ),
      ),
    );
  }
}
