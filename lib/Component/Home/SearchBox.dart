import 'package:flutter/material.dart';
import '../AppColour.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: AppColours.cardColor,
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.search,
              color:
              AppColours.secondaryText),
          SizedBox(width: 10),
          Text(
            "Search jobs, alumni...",
            style: TextStyle(
              color:
              AppColours.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}