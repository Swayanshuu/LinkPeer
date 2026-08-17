import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/alumni/models/alumni_event_model.dart';
import 'package:igit_connects/features/alumni/providers/alumni_provider.dart';
import 'package:igit_connects/features/alumni/screens/event_details_screen.dart';

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Past

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isPast = _selectedTab == 1;
    final eventsAsync =
        ref.watch(isPast ? alumniPastEventsProvider : alumniEventsProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: colors.borderColor.withValues(alpha: 0.5),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alumni Events',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Segmented Control (Upcoming vs Past)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.borderColor.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentPill(
                      context,
                      colors,
                      title: 'Upcoming',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentPill(
                      context,
                      colors,
                      title: 'Past',
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: RefreshIndicator(
              color: colors.primaryAccent,
              backgroundColor: colors.cardColor,
              onRefresh: () async {
                if (isPast) {
                  return ref.refresh(alumniPastEventsProvider.future);
                } else {
                  return ref.refresh(alumniEventsProvider.future);
                }
              },
              child: eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return _buildEmptyState(context, colors, isPast);
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(context, colors, event, isPast);
                    },
                  );
                },
                loading: () => _buildShimmerLoading(colors),
                error: (error, stackTrace) =>
                    _buildErrorState(context, colors, isPast, error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentPill(
    BuildContext context,
    AppColors colors, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? colors.onPrimaryAccent : colors.secondaryText,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    AppColors colors,
    AlumniEvent event,
    bool isPast,
  ) {
    final isHighPriority = event.priority.toLowerCase() == 'high';

    return Material(
      color: colors.cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailsScreen(event: event),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighPriority && !isPast
                  ? colors.primaryAccent.withValues(alpha: 0.4)
                  : colors.borderColor.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge Column (e.g., 16 AUG)
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isPast
                      ? colors.borderColor.withValues(alpha: 0.3)
                      : colors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPast
                        ? colors.borderColor
                        : colors.primaryAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.formattedDateBadge,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isPast ? colors.secondaryText : colors.primaryAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Content Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Priority Tag / Past Tag
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isPast) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.borderColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Archived',
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (event.priority.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isHighPriority
                                  ? Colors.redAccent.withValues(alpha: 0.12)
                                  : colors.borderColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              event.priority,
                              style: TextStyle(
                                color: isHighPriority
                                    ? Colors.redAccent
                                    : colors.secondaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Time & Location
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: colors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.time,
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.secondaryText.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Organizer tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'By ${event.organizer}',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(
                                color: colors.primaryAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: colors.primaryAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(AppColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Shimmer.fromColors(
            baseColor: colors.borderColor.withValues(alpha: 0.3),
            highlightColor: colors.cardColor,
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors colors, bool isPast) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPast
                    ? colors.secondaryText.withValues(alpha: 0.1)
                    : colors.categoryInternship.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPast ? Icons.history_rounded : Icons.event_busy_rounded,
                size: 48,
                color: isPast ? colors.secondaryText : colors.categoryInternship,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPast ? 'No archived events found' : 'No upcoming events',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPast
                  ? 'The past events archive is currently empty.'
                  : "New alumni events will appear here when they're announced.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                if (isPast) {
                  ref.invalidate(alumniPastEventsProvider);
                } else {
                  ref.invalidate(alumniEventsProvider);
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryAccent,
                side: BorderSide(color: colors.primaryAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppColors colors,
    bool isPast,
    Object error,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Colors.redAccent.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Events',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceAll('AlumniApiException: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (isPast) {
                  ref.invalidate(alumniPastEventsProvider);
                } else {
                  ref.invalidate(alumniEventsProvider);
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.onPrimaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
