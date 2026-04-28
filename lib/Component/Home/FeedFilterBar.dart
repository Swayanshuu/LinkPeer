import 'package:flutter/material.dart';

import '../AppColour.dart';

class FeedFilterBar extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;

  const FeedFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = ["all", "job", "announcement", "internship"];

    return SizedBox(
      height: 46,

      child: Row(
        children: items.map((item) {
          final active = selected == item;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),

              child: GestureDetector(
                onTap: () {
                  onChanged(item);
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),

                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: active
                        ? AppColours.primaryText
                        : AppColours.cardColor,

                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(
                      color: active
                          ? AppColours.primaryText
                          : AppColours.borderColor,
                    ),
                  ),

                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        item.toUpperCase(),
                        maxLines: 1,
                        style: TextStyle(
                          color: active ? Colors.black : AppColours.primaryText,

                          fontWeight: FontWeight.bold,

                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
