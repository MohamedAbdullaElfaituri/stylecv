import 'package:flutter/material.dart';

class CustomDynamicSection extends StatelessWidget {
  final String title;
  final String? description;
  final Widget Function(int index, BuildContext context) itemBuilder;
  final VoidCallback onAdd;
  final VoidCallback? onRemoveAll;
  final int itemCount;
  final Color accentColor;
  final Widget Function(String title, String? description)? buildSectionHeader;
  final EdgeInsetsGeometry? itemPadding;
  final bool showDivider;
  final Color dividerColor;
  final double dividerHeight;
  final bool showItemCount;
  final String addButtonTooltip;
  final String removeAllButtonTooltip;

  const CustomDynamicSection({
    Key? key,
    required this.title,
    this.description,
    required this.itemBuilder,
    required this.onAdd,
    this.onRemoveAll,
    required this.itemCount,
    this.accentColor = const Color(0xff142831),
    this.buildSectionHeader,
    this.itemPadding,
    this.showDivider = true,
    this.dividerColor = Colors.grey,
    this.dividerHeight = 1.0,
    this.showItemCount = true,
    this.addButtonTooltip = 'Add new item',
    this.removeAllButtonTooltip = 'Remove all items',
  }) : super(key: key);

  Widget _defaultSectionHeader(String title, String? description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: accentColor,
            letterSpacing: 0.5,
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: buildSectionHeader?.call(title, description) ??
                  _defaultSectionHeader(title, description),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRemoveAll != null && itemCount > 0)
                  Tooltip(
                    message: removeAllButtonTooltip,
                    child: IconButton(
                      icon: Icon(Icons.delete_sweep, color: Colors.red[400]),
                      onPressed: onRemoveAll,
                      splashRadius: 20,
                    ),
                  ),
                const SizedBox(width: 8),
                Tooltip(
                  message: addButtonTooltip,
                  child: FloatingActionButton.small(
                    onPressed: onAdd,
                    backgroundColor: accentColor,
                    child: const Icon(Icons.add, color: Colors.white),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    heroTag: null,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (showItemCount && itemCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(
              '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (showDivider && itemCount > 0)
          Divider(
            color: dividerColor,
            height: dividerHeight,
            thickness: dividerHeight,
          ),
        ...List.generate(
          itemCount,
              (index) => Padding(
            padding: itemPadding ?? const EdgeInsets.only(bottom: 12.0),
            child: Column(
              children: [
                itemBuilder(index, context),
                if (showDivider && index < itemCount - 1)
                  Divider(
                    color: dividerColor.withOpacity(0.3),
                    height: dividerHeight,
                    thickness: dividerHeight,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}