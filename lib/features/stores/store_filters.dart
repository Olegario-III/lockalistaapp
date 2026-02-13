// lib\features\stores\store_filters.dart
import 'package:flutter/material.dart';

class StoreFilters extends StatelessWidget {
  final List<String> storeTypes;
  final Map<String, IconData> storeTypeIcons;
  final List<String> barangays;

  final String? selectedType;
  final String? selectedBarangay;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onBarangayChanged;
  final ValueChanged<String> onSearchChanged;

  const StoreFilters({
    super.key,
    required this.storeTypes,
    required this.storeTypeIcons,
    required this.barangays,
    required this.selectedType,
    required this.selectedBarangay,
    required this.onTypeChanged,
    required this.onBarangayChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          /// 🔹 STORE TYPE FILTER
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: storeTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final type = storeTypes[index];

                /// ✅ Highlight if selected or matches a custom type
                final selected = selectedType != null && selectedType!.toLowerCase() == type.toLowerCase();

                return GestureDetector(
                  onTap: () {
                    onTypeChanged(selected ? null : type);
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                        child: Icon(
                          storeTypeIcons[type],
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          /// 🔹 BARANGAY FILTER
          DropdownButtonFormField<String>(
            initialValue: selectedBarangay,
            hint: const Text('Filter by Barangay'),
            items: barangays
                .map(
                  (b) => DropdownMenuItem(
                    value: b,
                    child: Text(b),
                  ),
                )
                .toList(),
            onChanged: onBarangayChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: 8),

          /// 🔹 SEARCH
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search store name...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => onSearchChanged(value.trim()),
          ),
        ],
      ),
    );
  }
}
