import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/endpoints.dart';
import '../core/data/dummy_events.dart';
import '../models/event.dart';
import 'api_client_provider.dart';

/// Fetches GET /api/events/trending. Uses dummy data when [useDummyData] is true.
final trendingEventsProvider = FutureProvider.autoDispose<List<EventListItem>>((ref) async {
  if (useDummyData) return dummyEventListItems;
  final client = ref.watch(apiClientProvider);
  final response = await client.get<List<dynamic>>(
    Endpoints.eventsTrending,
    queryParameters: {'limit': 20, 'offset': 0},
  );
  final list = response.data;
  if (list == null) return [];
  final items = list
      .map((e) => EventListItem.fromJson(e as Map<String, dynamic>))
      .toList();
  // Debug: log how many trending events came from the API.
  // This prints to the Flutter console so you can inspect the count.
  // Remove this when you no longer need it.
  // ignore: avoid_print
  print('Trending events count: ${items.length}');
  return items;
});
