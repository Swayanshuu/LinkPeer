import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/update/update_model.dart';
import 'package:igit_connects/core/update/update_service.dart';

class UpdateStateData {
  final bool hasUpdate;
  final UpdateModel? updateInfo;

  UpdateStateData({required this.hasUpdate, this.updateInfo});
}

class UpdateNotifier extends AsyncNotifier<UpdateStateData> {
  final UpdateService _updateService = UpdateService();

  @override
  Future<UpdateStateData> build() async {
    return await _fetchUpdates();
  }

  Future<UpdateStateData> _fetchUpdates() async {
    final updateInfo = await _updateService.fetchUpdateInfo();
    final hasUpdate = await _updateService.hasUpdate();
    return UpdateStateData(hasUpdate: hasUpdate, updateInfo: updateInfo);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final result = await _fetchUpdates();
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> checkForUpdates() async {
    await refresh();
  }
}

final updateProvider = AsyncNotifierProvider<UpdateNotifier, UpdateStateData>(
  () => UpdateNotifier(),
);
