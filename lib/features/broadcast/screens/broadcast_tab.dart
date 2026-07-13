import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/features/broadcast/components/broadcast_card.dart';
import 'package:igit_connects/features/broadcast/models/broadcast_model.dart';
import 'package:igit_connects/features/broadcast/services/broadcast_service.dart';
import 'package:shimmer/shimmer.dart';

class BroadcastTab extends ConsumerStatefulWidget {
  const BroadcastTab({super.key});

  @override
  ConsumerState<BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends ConsumerState<BroadcastTab> {
  final BroadcastService _broadcastService = BroadcastService();
  final ScrollController _scrollController = ScrollController();
  final List<BroadcastModel> _broadcasts = [];
  
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 50;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchBroadcasts();
      }
    });
  }

  Future<void> _fetchBroadcasts() async {
    if (_isLoading || _userType == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final newBroadcasts = await _broadcastService.getBroadcasts(
        offset: _offset,
        limit: _limit,
        userType: _userType!,
      );

      if (mounted) {
        setState(() {
          _offset += newBroadcasts.length;
          _broadcasts.addAll(newBroadcasts);
          if (newBroadcasts.length < _limit) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching broadcasts: \$e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildShimmer(AppColors colors) {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 300,
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Shimmer.fromColors(
            baseColor: colors.borderColor,
            highlightColor: colors.bgColor,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (userData) {
        if (_userType == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _userType == null) {
              setState(() {
                _userType = userData['user_type'] as String? ?? 'guest';
              });
              _fetchBroadcasts();
            }
          });
          return _buildShimmer(colors);
        }

        if (_broadcasts.isEmpty && _isLoading) {
          return _buildShimmer(colors);
        }

        if (_broadcasts.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _offset = 0;
                _broadcasts.clear();
                _hasMore = true;
              });
              await _fetchBroadcasts();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: colors.secondaryText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No announcements yet",
                        style: TextStyle(color: colors.secondaryText, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _offset = 0;
              _broadcasts.clear();
              _hasMore = true;
            });
            await _fetchBroadcasts();
          },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _broadcasts.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
              if (index == _broadcasts.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final broadcast = _broadcasts[index];
              final isAdmin = userData['role']?.toString().toLowerCase() == 'admin' ||
                              userData['user_type']?.toString().toLowerCase() == 'admin';
                              
              return BroadcastCard(
                broadcast: broadcast,
                isAdmin: isAdmin,
                onDeleteSuccess: () {
                  setState(() {
                    _broadcasts.removeAt(index);
                  });
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: colors.cardColor,
                        title: Text(
                          "Delete Broadcast",
                          style: TextStyle(
                            color: colors.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          "Are you sure you want to delete this broadcast? This action cannot be undone.",
                          style: TextStyle(color: colors.secondaryText),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: colors.secondaryText),
                            ),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      await _broadcastService.deleteBroadcast(
                        broadcast.id,
                        imageUrl: broadcast.imageUrl,
                      );
                      setState(() {
                        _broadcasts.removeAt(index);
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Broadcast deleted successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to delete broadcast')),
                        );
                      }
                    }
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => _buildShimmer(colors),
      error: (error, stack) => Center(
        child: Text(
          "Error loading user profile",
          style: TextStyle(color: colors.primaryText),
        ),
      ),
    );
  }
}
