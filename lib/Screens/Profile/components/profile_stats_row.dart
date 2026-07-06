// Component/Profile/ProfileStatsRow.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igit_connects/screens/profile/components/profile_stats_box.dart';

class ProfileStatsRow extends StatelessWidget {
  final Map data;
  final AsyncValue posts;

  const ProfileStatsRow({
    super.key,
    required this.data,
    required this.posts,
  });

  @override
  Widget build(
      BuildContext context) {

    final type =
    (data["user_type"] ??
        "student")
        .toString();

    final branch =
    (data["branch"] ??
        "")
        .toString();

    final dept =
    (data["department"] ??
        "")
        .toString();

    final count =
    posts.maybeWhen(
      data: (list) => list
          .where(
            (p) =>
        p["user_id"] ==
            data["id"],
      )
          .length
          .toString(),
      orElse: () => "0",
    );

    return Row(
      mainAxisAlignment:
      MainAxisAlignment
          .spaceAround,

      children: [
        ProfileStatBox(
          title: "Posts",
          value: count,
        ),

        ProfileStatBox(
          title: "Type",
          value:
          type.toUpperCase(),
        ),

        ProfileStatBox(
          title: type ==
              "faculty"
              ? "Dept"
              : "Branch",

          value: type ==
              "faculty"
              ? dept
              : branch,
        ),
      ],
    );
  }
}