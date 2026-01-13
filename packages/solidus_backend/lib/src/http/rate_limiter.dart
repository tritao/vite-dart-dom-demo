import 'package:shelf/shelf.dart';

class RateLimitRule {
  RateLimitRule({
    required this.key,
    required this.window,
    required this.maxHits,
  });

  final String key;
  final Duration window;
  final int maxHits;
}

class InMemoryRateLimiter {
  InMemoryRateLimiter({this.maxEntries = 5000});

  final int maxEntries;
  final _buckets = <String, _Bucket>{};

  bool allow(String key, RateLimitRule rule, DateTime now) {
    final composite = '${rule.key}:$key';
    final bucket = _buckets.putIfAbsent(
      composite,
      () => _Bucket(window: rule.window, maxHits: rule.maxHits, startedAt: now, hits: 0),
    );
    _buckets.remove(composite);
    _buckets[composite] = bucket;

    if (now.difference(bucket.startedAt) >= bucket.window) {
      bucket.startedAt = now;
      bucket.hits = 0;
    }
    bucket.hits++;
    _evictIfNeeded();
    return bucket.hits <= bucket.maxHits;
  }

  void _evictIfNeeded() {
    while (_buckets.length > maxEntries) {
      _buckets.remove(_buckets.keys.first);
    }
  }
}

class _Bucket {
  _Bucket({
    required this.window,
    required this.maxHits,
    required this.startedAt,
    required this.hits,
  });

  final Duration window;
  final int maxHits;
  DateTime startedAt;
  int hits;
}

Middleware rateLimitMiddleware({
  required InMemoryRateLimiter limiter,
  required List<RateLimitRule> rules,
  required String Function(Request request) keyFor,
  required bool Function(Request request) appliesTo,
  required Response Function() onLimited,
}) {
  return (inner) {
    return (request) async {
      if (!appliesTo(request)) return inner(request);
      final now = DateTime.now().toUtc();
      final key = keyFor(request);
      for (final rule in rules) {
        if (!limiter.allow(key, rule, now)) return onLimited();
      }
      return inner(request);
    };
  };
}
