import 'package:flutter/material.dart';

class ProductSelector extends StatelessWidget {
  const ProductSelector({
    super.key,
    required this.products,
    required this.selectedKeys,
    required this.quantityControllers,
    required this.loading,
    required this.error,
    required this.keyFor,
    required this.labelFor,
    required this.onToggle,
    required this.onAdjustQuantity,
    required this.onRetry,
  });

  final List<Map<String, dynamic>> products;
  final Set<String> selectedKeys;
  final Map<String, TextEditingController> quantityControllers;
  final bool loading;
  final String? error;
  final String Function(int) keyFor;
  final String Function(Map<String, dynamic>) labelFor;
  final void Function(int index, bool selected) onToggle;
  final void Function(String key, int change) onAdjustQuantity;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          FormField<Set<String>>(
            validator: (_) => selectedKeys.isEmpty ? 'Select at least one product' : null,
            builder: (field) => InputDecorator(
              decoration: InputDecoration(
                labelText: 'Products',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: const OutlineInputBorder(),
                errorText: field.errorText,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : products.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(error ?? 'No products found'),
                        )
                      : Column(
                          children: [
                            for (var index = 0; index < products.length; index++) ...[
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(labelFor(products[index])),
                                subtitle: Text(
                                  (products[index]['category']?['name'] ?? '').toString(),
                                ),
                                value: selectedKeys.contains(keyFor(index)),
                                onChanged: (checked) {
                                  onToggle(index, checked == true);
                                  field.didChange(Set<String>.from(selectedKeys));
                                },
                              ),
                              if (selectedKeys.contains(keyFor(index)))
                                Padding(
                                  padding: const EdgeInsets.only(left: 56, right: 12, bottom: 12),
                                  child: TextFormField(
                                    controller: quantityControllers[keyFor(index)],
                                    decoration: InputDecoration(
                                      labelText: 'Quantity',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Decrease quantity',
                                            onPressed: () => onAdjustQuantity(keyFor(index), -1),
                                            icon: const Icon(Icons.remove),
                                          ),
                                          IconButton(
                                            tooltip: 'Increase quantity',
                                            onPressed: () => onAdjustQuantity(keyFor(index), 1),
                                            icon: const Icon(Icons.add),
                                          ),
                                        ],
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (!selectedKeys.contains(keyFor(index))) return null;
                                      final quantity = int.tryParse(value?.trim() ?? '');
                                      return quantity == null || quantity < 1
                                          ? 'Enter a quantity greater than zero'
                                          : null;
                                    },
                                  ),
                                ),
                            ],
                          ],
                        ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry loading products'),
            ),
          ],
        ],
      );
}
