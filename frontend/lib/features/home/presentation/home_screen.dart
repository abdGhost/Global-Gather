import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_service.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/app_storage.dart';
import '../../../models/event.dart';
import '../../../providers/nearby_events_provider.dart';
import '../../../providers/trending_events_provider.dart';
import '../../../providers/user_location_provider.dart';
import 'widgets/event_card.dart';
import 'widgets/shimmer_event_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategoryIndex = 0;
  final _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isRequestingLocation = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final next = _scrollController.hasClients && _scrollController.offset > 2;
      if (next == _isScrolled) return;
      setState(() => _isScrolled = next);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);
    final trending = ref.watch(trendingEventsProvider);
    final userLocation = ref.watch(userLocationProvider);
    final nearby = userLocation == null
        ? const AsyncValue<List<EventListItem>>.data(<EventListItem>[])
        : ref.watch(
            nearbyEventsProvider(
              NearbyParams(
                lat: userLocation.lat,
                lng: userLocation.lng,
              ),
            ),
          );

    // Derive dynamic categories from currently available events so we only
    // show categories that actually exist.
    final categories = trending.maybeWhen(
      data: (events) {
        final set = <String>{};
        for (final e in events) {
          final c = e.category?.trim();
          if (c != null && c.isNotEmpty) {
            set.add(c);
          }
        }
        final list = set.toList()..sort();
        return list;
      },
      orElse: () => <String>[],
    );
    final hasCategories = categories.isNotEmpty;
    final selectedCategoryIndex = hasCategories
        ? _selectedCategoryIndex.clamp(0, categories.length - 1)
        : 0;

    return Scaffold(
      body: Stack(
        children: [
          // Soft gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.2, 1.0],
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: _isScrolled
                    ? Theme.of(context).colorScheme.surface
                    : Colors.transparent,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                titleSpacing: 0,
                toolbarHeight: Responsive.value(
                    context, Responsive.isCompact(context) ? 60 : 64),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 1,
                    color: _isScrolled
                        ? Colors.black.withValues(alpha: 0.06)
                        : Colors.transparent,
                  ),
                ),
                leading: Padding(
                  padding: EdgeInsets.only(
                    left: Responsive.horizontalPadding(context),
                    right: Responsive.spacing(context, 10),
                  ),
                  child: CircleAvatar(
                    radius: Responsive.appBarAvatarRadius(context),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      color: AppColors.primary,
                      size: Responsive.iconSize(
                        context,
                        Responsive.isCompact(context) ? 16 : 18,
                      ),
                    ),
                  ),
                ),
                // Extra spacing between profile icon and search box.
                leadingWidth: Responsive.appBarAvatarRadius(context) * 2 +
                    Responsive.spacing(context, 22),
                title: Padding(
                  padding:
                      EdgeInsets.only(right: Responsive.spacing(context, 8)),
                  child: _SearchBar(),
                ),
                actions: [
                  IconButton(
                    constraints: BoxConstraints.tightFor(
                      width: Responsive.value(context, 42),
                      height: Responsive.value(context, 42),
                    ),
                    icon: Container(
                      padding: EdgeInsets.all(
                          Responsive.value(context, compact ? 6 : 8)),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            Responsive.value(context, compact ? 10 : 12)),
                      ),
                      child: FaIcon(FontAwesomeIcons.sliders,
                          size: Responsive.iconSize(context, compact ? 16 : 18),
                          color: AppColors.primary),
                    ),
                    onPressed: () => _showFilterSheet(context),
                  ),
                  SizedBox(width: Responsive.horizontalPadding(context) - 4),
                ],
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: Responsive.spacing(context, 12))),
              SliverToBoxAdapter(
                child: trending.when(
                  data: (events) {
                    if (events.isEmpty) return const SizedBox.shrink();

                    // Apply category filter from chips (home screen).
                    List<EventListItem> visible = events;
                    if (hasCategories) {
                      final selectedCategory = categories[selectedCategoryIndex];
                      final filtered = events
                          .where(
                            (e) =>
                                e.category != null &&
                                e.category!.toLowerCase() ==
                                    selectedCategory.toLowerCase(),
                          )
                          .toList();
                      visible = filtered.isEmpty ? events : filtered;
                    }

                    // If there is only a single trending event, just show one
                    // large card without repeating it in a carousel. When
                    // there are multiple events, use the carousel.
                    if (visible.length == 1) {
                      final e = visible.first;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.horizontalPadding(context),
                        ),
                        child: SizedBox(
                          height: Responsive.trendingCarouselHeight(context),
                          child: EventCard(
                            event: e,
                            size: EventCardSize.large,
                            showGoingButton: false,
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: Responsive.trendingCarouselHeight(context),
                      child: CarouselSlider.builder(
                        itemCount: visible.length.clamp(0, 8),
                        itemBuilder: (_, i, __) {
                          final e = visible[i];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Responsive.spacing(context, 6)),
                            child: EventCard(
                                event: e,
                                size: EventCardSize.large,
                                showGoingButton: false),
                          );
                        },
                        options: CarouselOptions(
                          enlargeCenterPage: true,
                          viewportFraction: 0.88,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 5),
                          padEnds: false,
                        ),
                      ),
                    );
                  },
                  loading: () => SizedBox(
                    height: Responsive.trendingCarouselHeight(context),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: Responsive.horizontalPadding(context)),
                      itemCount: 3,
                      itemBuilder: (_, __) => Padding(
                        padding: EdgeInsets.only(
                            right: Responsive.spacing(context, 14)),
                        child: SizedBox(
                            width: Responsive.shimmerTrendingWidth(context),
                            child: const ShimmerEventCard(aspectRatio: 16 / 9)),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: Responsive.spacing(context, 28))),
              // Categories
              if (hasCategories)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPadding(context)),
                        child: Text('Categories',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                )),
                      ),
                      SizedBox(height: Responsive.spacing(context, 10)),
                      SizedBox(
                        height: Responsive.value(context, compact ? 32 : 40),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                Responsive.horizontalPadding(context),
                          ),
                          itemCount: categories.length,
                          itemBuilder: (_, i) {
                            final selected = selectedCategoryIndex == i;
                            return Padding(
                              padding: EdgeInsets.only(
                                right: Responsive.spacing(
                                    context, compact ? 8 : 10),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => setState(
                                      () => _selectedCategoryIndex = i),
                                  borderRadius: BorderRadius.circular(
                                    Responsive.value(
                                        context, compact ? 18 : 20),
                                  ),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.value(
                                          context, compact ? 12 : 18),
                                      vertical: Responsive.value(
                                          context, compact ? 6 : 10),
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryDark
                                          : AppColors.primary
                                              .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(
                                        Responsive.value(
                                            context, compact ? 18 : 20),
                                      ),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primaryDark
                                            : AppColors.primary
                                                .withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        categories[i],
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(
                                              context, compact ? 12 : 14),
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              SliverToBoxAdapter(
                  child: SizedBox(height: Responsive.spacing(context, 28))),
              // Events Near You
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Responsive.horizontalPadding(context)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                                Responsive.value(context, compact ? 6 : 8)),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  Responsive.value(context, compact ? 9 : 10)),
                            ),
                            child: FaIcon(FontAwesomeIcons.locationDot,
                                size: Responsive.iconSize(
                                    context, compact ? 16 : 18),
                                color: AppColors.primary),
                          ),
                          SizedBox(width: Responsive.spacing(context, 10)),
                          Text('Near you',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  )),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/map'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                              horizontal: Responsive.spacing(
                                  context, compact ? 8 : 12)),
                        ),
                        icon: FaIcon(FontAwesomeIcons.map,
                            size: Responsive.iconSize(
                                context, compact ? 14 : 16)),
                        label: const Text('Map'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: Responsive.spacing(context, 12))),
              SliverToBoxAdapter(
                child: nearby.when(
                  data: (events) {
                    final hasLocation = userLocation != null;
                    if (events.isEmpty && !hasLocation) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPadding(context)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: Responsive.value(context, 24),
                              horizontal:
                                  Responsive.horizontalPadding(context)),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                                Responsive.value(context, 16)),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                    Responsive.value(context, compact ? 6 : 8)),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.locationCrosshairs,
                                  size: Responsive.iconSize(context, 18),
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: Responsive.spacing(context, 14)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Allow location to see events near you',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.86,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    SizedBox(
                                        height:
                                            Responsive.spacing(context, 4)),
                                    Text(
                                      'Tap the button below—we\'ll ask for permission. Or use the map to pick a location.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                    ),
                                    SizedBox(
                                        height:
                                            Responsive.spacing(context, 8)),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton(
                                        onPressed: _isRequestingLocation
                                            ? null
                                            : () async {
                                                setState(() =>
                                                    _isRequestingLocation =
                                                        true);
                                                final result =
                                                    await LocationService
                                                        .requestAndGetCurrentPosition();
                                                if (!mounted) return;
                                                setState(() =>
                                                    _isRequestingLocation =
                                                        false);
                                                if (result.isSuccess &&
                                                    result.position != null) {
                                                  final pos = result.position!;
                                                  ref
                                                      .read(userLocationProvider
                                                          .notifier)
                                                      .state = (
                                                    lat: pos.latitude,
                                                    lng: pos.longitude,
                                                  );
                                                  await AppStorage
                                                      .saveUserLocation(
                                                    pos.latitude,
                                                    pos.longitude,
                                                  );
                                                  return;
                                                }
                                                final reason =
                                                    result.failureReason;
                                                if (reason ==
                                                    LocationFailureReason
                                                        .serviceDisabled) {
                                                  await LocationService
                                                      .openLocationSettings();
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Turn on Location in device settings, then tap Allow location again.'),
                                                      duration: Duration(seconds: 5),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                if (reason ==
                                                    LocationFailureReason
                                                        .timeoutOrError) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Could not get location. Ensure Location is on and try again.'),
                                                      duration: Duration(seconds: 4),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Allow location when prompted to see events near you.'),
                                                    duration: Duration(seconds: 4),
                                                  ),
                                                );
                                              },
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryDark,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Responsive.value(
                                                context, 14),
                                            vertical: Responsive.value(
                                                context, 8),
                                          ),
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Allow location',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (events.isEmpty && hasLocation) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPadding(context)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: Responsive.value(context, 24),
                              horizontal:
                                  Responsive.horizontalPadding(context)),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                                Responsive.value(context, 16)),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                    Responsive.value(context, compact ? 6 : 8)),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.locationDot,
                                  size: Responsive.iconSize(context, 18),
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: Responsive.spacing(context, 14)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'No events near your location yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.86,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    SizedBox(
                                        height:
                                            Responsive.spacing(context, 4)),
                                    Text(
                                      'Try adjusting the map or exploring trending events.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: Responsive.nearYouListHeight(context),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPadding(context)),
                        itemCount: events.length,
                        itemBuilder: (_, i) {
                          return Padding(
                            padding: EdgeInsets.only(
                                right: Responsive.spacing(context, 14)),
                            child: SizedBox(
                              width: Responsive.smallCardWidth(context),
                              child: EventCard(
                                  event: events[i], size: EventCardSize.small),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Responsive.horizontalPadding(context)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: Responsive.value(context, 20),
                          horizontal: Responsive.horizontalPadding(context)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                            Responsive.value(context, 16)),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade300,
                          ),
                          SizedBox(
                              width: Responsive.spacing(context, 10)),
                          Expanded(
                            child: Text(
                              'Could not load events near you. Check console logs for details.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.red.shade200,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: Responsive.spacing(context, 28))),
              // This Week
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Responsive.horizontalPadding(context)),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.value(context, 8)),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              Responsive.value(context, 10)),
                        ),
                        child: FaIcon(FontAwesomeIcons.calendarDays,
                            size: Responsive.iconSize(context, 18),
                            color: AppColors.primary),
                      ),
                      SizedBox(width: Responsive.spacing(context, 10)),
                      Text('This week',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  )),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: Responsive.spacing(context, 14))),
              trending.when(
                data: (events) {
                  // If we have only a few events, also show them here.
                  // When there are many, we could later slice to a true
                  // \"this week\" subset, but for now reuse the list.
                  if (events.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPadding(context)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: Responsive.value(context, 48),
                              horizontal: Responsive.value(context, 24)),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                                Responsive.value(context, 20)),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                    Responsive.value(context, 10)),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.calendarCheck,
                                  size: Responsive.iconSize(context, 26),
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: Responsive.spacing(context, 16)),
                              Text(
                                'No upcoming events this week',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: Responsive.spacing(context, 6)),
                              Text(
                                'Try exploring by category or zooming the map to discover more.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.72),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        Responsive.horizontalPadding(context),
                        0,
                        Responsive.horizontalPadding(context),
                        Responsive.spacing(context, 32)),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: Responsive.spacing(context, 14)),
                            child: EventCard(event: events[i]),
                          )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 50 * i))
                              .slideY(
                                  begin: 0.03, end: 0, curve: Curves.easeOut);
                        },
                        childCount: events.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      Responsive.horizontalPadding(context),
                      0,
                      Responsive.horizontalPadding(context),
                      Responsive.spacing(context, 32)),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => Padding(
                        padding: EdgeInsets.only(
                            bottom: Responsive.spacing(context, 14)),
                        child: const ShimmerEventCard(aspectRatio: 4 / 3),
                      ),
                      childCount: 5,
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.all(Responsive.horizontalPadding(context)),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.circleExclamation,
                              size: Responsive.iconSize(context, 40),
                              color: Colors.red.shade300),
                          SizedBox(height: Responsive.spacing(context, 12)),
                          Text('Something went wrong',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.red.shade700)),
                          SizedBox(height: Responsive.spacing(context, 4)),
                          Text('$e',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomNavHeight = 80.0;
        final bottomPadding = MediaQuery.paddingOf(ctx).bottom + bottomNavHeight;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Container(
            width: MediaQuery.sizeOf(ctx).width,
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: true,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.horizontalPadding(ctx) + 4,
                  Responsive.horizontalPadding(ctx) + 4,
                  Responsive.horizontalPadding(ctx) + 4,
                  Responsive.spacing(ctx, 16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Filters',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    SizedBox(height: Responsive.spacing(ctx, 20)),
                    ListTile(
                        title: const Text('Date'),
                        trailing: FaIcon(FontAwesomeIcons.calendarDays,
                            size: Responsive.iconSize(ctx, 20))),
                    ListTile(
                        title: const Text('Category'),
                        trailing: FaIcon(FontAwesomeIcons.tags,
                            size: Responsive.iconSize(ctx, 20))),
                    ListTile(
                        title: const Text('Virtual / In-person'),
                        trailing: FaIcon(FontAwesomeIcons.arrowsLeftRight,
                            size: Responsive.iconSize(ctx, 20))),
                    ListTile(
                        title: const Text('Free / Paid'),
                        trailing: FaIcon(FontAwesomeIcons.dollarSign,
                            size: Responsive.iconSize(ctx, 20))),
                    ListTile(
                        title: const Text('Country'),
                        trailing: FaIcon(FontAwesomeIcons.globe,
                            size: Responsive.iconSize(ctx, 20))),
                    SizedBox(height: Responsive.spacing(ctx, 24)),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.value(
                              ctx, Responsive.isCompact(ctx) ? 12 : 14),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Responsive.value(ctx, 14))),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);
    final radius = Responsive.value(context, 22);
    // Keep same color on hover, just a bit more opaque.
    final bg = AppColors.primary.withValues(alpha: _hovered ? 0.16 : 0.10);
    final border = AppColors.primary.withValues(alpha: 0.25);
    final iconColor = AppColors.primaryDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: Responsive.searchBarHeight(context),
          decoration: BoxDecoration(
            // Match category chip style.
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onHover: (v) {
                if (_hovered == v) return;
                setState(() => _hovered = v);
              },
              onTap: () => context.go('/search'),
              child: SizedBox(
                width: double.infinity,
                height: Responsive.searchBarHeight(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.value(context, compact ? 14 : 18),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: Responsive.value(context, 36),
                        child: Center(
                          child: Icon(
                            FontAwesomeIcons.magnifyingGlass,
                            size: Responsive.iconSize(context, compact ? 18 : 20),
                            color: iconColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Search events, places...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                          color: AppColors.primaryDark,
                            fontSize: Responsive.fontSize(context, compact ? 14 : 15),
                            height: 1.1,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.value(context, 34),
                        child: Center(
                          child: Icon(
                            FontAwesomeIcons.microphone,
                            size: Responsive.iconSize(context, compact ? 16 : 18),
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
