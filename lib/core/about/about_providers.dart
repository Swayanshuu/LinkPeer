import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/about/developer_profile_model.dart';
import 'package:igit_connects/core/about/developer_profile_service.dart';
import 'package:igit_connects/core/about/support_links_model.dart';
import 'package:igit_connects/core/about/support_links_service.dart';

class DeveloperProfileNotifier extends AsyncNotifier<DeveloperProfileModel?> {
  final DeveloperProfileService _service = DeveloperProfileService();

  @override
  Future<DeveloperProfileModel?> build() async {
    return await _service.fetchProfile();
  }
}

final developerProfileProvider =
    AsyncNotifierProvider<DeveloperProfileNotifier, DeveloperProfileModel?>(
  () => DeveloperProfileNotifier(),
);

class SupportLinksNotifier extends AsyncNotifier<SupportLinksModel?> {
  final SupportLinksService _service = SupportLinksService();

  @override
  Future<SupportLinksModel?> build() async {
    return await _service.fetchLinks();
  }
}

final supportLinksProvider =
    AsyncNotifierProvider<SupportLinksNotifier, SupportLinksModel?>(
  () => SupportLinksNotifier(),
);
