import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

class AppDropdownFormField<T> extends FormField<T> {
  final T? value;
  final String label;
  final IconData? icon;
  final List<T> items;
  final String Function(T item)? itemLabelBuilder;
  final ValueChanged<T?>? onChanged;

  AppDropdownFormField({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    required this.items,
    this.itemLabelBuilder,
    required this.onChanged,
    super.validator,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<T> state) {
            final context = state.context;
            final colors = AppColors.of(context);
            final isDark = Theme.of(context).brightness == Brightness.dark;

            T? findValidValue() {
              if (items.contains(value)) return value;
              if (items.contains(state.value)) return state.value;
              if (value is String && (value as String).trim().isNotEmpty) {
                final valStr = (value as String).trim().toLowerCase();
                for (final item in items) {
                  if (item.toString().trim().toLowerCase() == valStr) {
                    return item;
                  }
                }
              }
              if (state.value is String &&
                  (state.value as String).trim().isNotEmpty) {
                final valStr = (state.value as String).trim().toLowerCase();
                for (final item in items) {
                  if (item.toString().trim().toLowerCase() == valStr) {
                    return item;
                  }
                }
              }
              return null;
            }

            final validValue = findValidValue();
            final displayLabel = validValue != null
                ? (itemLabelBuilder != null
                    ? itemLabelBuilder(validValue)
                    : validValue.toString())
                : null;

            return InkWell(
              onTap: () async {
                final selected = await showModalBottomSheet<T>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: colors.cardColor,
                  barrierColor: Colors.black.withValues(alpha: 0.5),
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) {
                    return _AppSelectionSheet<T>(
                      title: label,
                      items: items,
                      selectedValue: validValue,
                      itemLabelBuilder: itemLabelBuilder,
                    );
                  },
                );

                if (selected != null) {
                  state.didChange(selected);
                  if (onChanged != null) {
                    onChanged(selected);
                  }
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 14,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: colors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: icon != null
                      ? Icon(icon, color: colors.secondaryText, size: 20)
                      : null,
                  suffixIcon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.secondaryText,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? colors.bgColor.withValues(alpha: 0.6)
                      : colors.bgColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: state.hasError
                          ? Theme.of(context).colorScheme.error
                          : colors.borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: colors.primaryAccent, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                  errorText: state.errorText,
                ),
                child: Text(
                  displayLabel ?? "",
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
}

class _AppSelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T item)? itemLabelBuilder;

  const _AppSelectionSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    this.itemLabelBuilder,
  });

  @override
  State<_AppSelectionSheet<T>> createState() => _AppSelectionSheetState<T>();
}

class _AppSelectionSheetState<T> extends State<_AppSelectionSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredItems = widget.items.where((item) {
      final label = widget.itemLabelBuilder != null
          ? widget.itemLabelBuilder!(item)
          : item.toString();
      return label.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select ${widget.title}",
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.secondaryText,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Optional Search Bar for large lists (> 5 items)
          if (widget.items.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: colors.primaryText, fontSize: 14),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: "Search ${widget.title}...",
                  hintStyle: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colors.secondaryText,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? colors.bgColor.withValues(alpha: 0.6)
                      : colors.bgColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: colors.primaryAccent, width: 1.5),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          Divider(height: 1, color: colors.borderColor.withValues(alpha: 0.5)),

          // Items List
          Flexible(
            child: filteredItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Text(
                      "No options found",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (ctx, idx) {
                      final item = filteredItems[idx];
                      final label = widget.itemLabelBuilder != null
                          ? widget.itemLabelBuilder!(item)
                          : item.toString();
                      final isSelected = item == widget.selectedValue;

                      return Material(
                        color: isSelected
                            ? colors.primaryAccent.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Navigator.pop(context, item),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? colors.primaryAccent
                                        .withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? colors.primaryAccent
                                          : colors.primaryText,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colors.primaryAccent,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
