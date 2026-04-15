import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TraVuSelect<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemAsString;
  final Function(T?) onChanged;
  final IconData? prefixIcon;

  const TraVuSelect({
    Key? key,
    this.label = '',
    required this.items,
    required this.itemAsString,
    required this.onChanged,
    this.hint = "Select an option",
    this.value,
    this.prefixIcon,
  }) : super(key: key);

  void _showSelectionSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (label.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map((item) {
                    final isSelected = item == value;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(itemAsString(item), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
                      onTap: () {
                        onChanged(item);
                        Get.back();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
  isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: () => _showSelectionSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, color: Colors.grey),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    value != null ? itemAsString(value as T) : hint,
                    style: TextStyle(
                      color: value != null ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
