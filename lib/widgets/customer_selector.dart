import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CustomerSelector extends StatelessWidget {
  const CustomerSelector({
    super.key,
    required this.geofences,
    required this.selectedKey,
    required this.loading,
    required this.error,
    required this.searchController,
    required this.keyFor,
    required this.nameFor,
    required this.onChanged,
    required this.onRetry,
  });

  final List<Map<String, dynamic>> geofences;
  final String? selectedKey;
  final bool loading;
  final String? error;
  final TextEditingController searchController;
  final String Function(int) keyFor;
  final String Function(Map<String, dynamic>) nameFor;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          DropdownButtonFormField2<String>(
            value: selectedKey,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Customer / Geofence',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            hint: Text(loading
                ? 'Loading geofence list...'
                : error ?? (geofences.isEmpty ? 'No geofences found' : 'Select a geofence')),
            items: [
              for (var index = 0; index < geofences.length; index++)
                DropdownMenuItem(
                  value: keyFor(index),
                  child: Text(nameFor(geofences[index])),
                ),
            ],
            onChanged: loading || geofences.isEmpty ? null : onChanged,
            validator: (value) => value == null ? 'Select a customer geofence' : null,
            dropdownStyleData: const DropdownStyleData(maxHeight: 320),
            dropdownSearchData: DropdownSearchData<String>(
              searchController: searchController,
              searchInnerWidgetHeight: 64,
              searchInnerWidget: Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search customer...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              searchMatchFn: (item, searchValue) {
                final geofence = geofences.firstWhere(
                  (entry) => keyFor(geofences.indexOf(entry)) == item.value,
                );
                return nameFor(geofence).toLowerCase().contains(searchValue.toLowerCase());
              },
            ),
            onMenuStateChange: (isOpen) {
              if (!isOpen) searchController.clear();
            },
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry loading geofences'),
            ),
          ],
        ],
      );
}
