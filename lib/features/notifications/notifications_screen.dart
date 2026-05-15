import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const int _pageSize = 10;

  final List<_UiNotification> _items = <_UiNotification>[];
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoadingInitial = true;
      _error = null;
      _page = 0;
      _hasMore = true;
      _items.clear();
    });
    await _loadPage(reset: true);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoadingInitial) return;
    setState(() => _isLoadingMore = true);
    await _loadPage();
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    try {
      final targetPage = reset ? 0 : _page;
      final data = await ref
          .read(backendApiProvider)
          .notificationsPage(page: targetPage, size: _pageSize);
      final parsed = _extractNotifications(data);

      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(parsed);
          _page = 1;
        } else {
          _items.addAll(parsed);
          _page += 1;
        }
        _hasMore = _extractHasMore(data, parsed.length, _pageSize);
        _isLoadingInitial = false;
        _error = null;
      });
      ref.invalidate(unreadNotificationsCountProvider);
      ref.invalidate(latestNotificationsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFacingMessage(e);
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _markAsRead(_UiNotification item) async {
    if (item.id == null || item.isRead) return;
    await ref.read(backendApiProvider).notificationsMarkRead(item.id!);
    if (!mounted) return;
    setState(() {
      final index = _items.indexOf(item);
      if (index >= 0) {
        _items[index] = item.copyWith(isRead: true);
      }
    });
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(latestNotificationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          IconButton(
            onPressed: _isLoadingInitial ? null : _loadInitial,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.l10n.refresh,
          ),
        ],
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadInitial)
              : _items.isEmpty
                  ? _EmptyState(onRefresh: _loadInitial)
                  : RefreshIndicator(
                      onRefresh: _loadInitial,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      final metrics = notification.metrics;
                      if (metrics.pixels > metrics.maxScrollExtent - 220) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = _items[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _markAsRead(item),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? AppColors.surface
                                  : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isRead
                                    ? AppColors.borderLight
                                    : AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: item.isRead
                                            ? AppColors.textTertiary
                                            : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: titleStyle?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.relativeTime,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                                if (item.type != null && item.type!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      item.type!,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                  item.message,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'When you get notifications, they\'ll show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.refresh),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 28),
            const SizedBox(height: 10),
            Text(
              'Failed to load notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

List<_UiNotification> _extractNotifications(Map<String, dynamic> data) {
  final raw = data['content'];
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map(
          (item) => _UiNotification.fromMap(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList();
  }
  return const <_UiNotification>[];
}

bool _extractHasMore(Map<String, dynamic> data, int fetchedCount, int pageSize) {
  final last = data['last'];
  if (last is bool) return !last;

  final totalPages = data['totalPages'];
  final number = data['number'];
  if (totalPages is num && number is num) {
    return number.toInt() + 1 < totalPages.toInt();
  }
  return fetchedCount >= pageSize;
}

class _UiNotification {
  const _UiNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String? id;
  final String title;
  final String message;
  final String? type;
  final DateTime? createdAt;
  final bool isRead;

  String get relativeTime {
    final ts = createdAt;
    if (ts == null) return 'now';
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '${weeks}w';
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  _UiNotification copyWith({bool? isRead}) {
    return _UiNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory _UiNotification.fromMap(Map<String, dynamic> map) {
    final title =
        _readString(map, const ['title', 'heading', 'subject']) ?? 'Notification';
    final message =
        _readString(map, const ['message', 'body', 'content', 'description']) ??
            'You have a new update.';
    final type = _readString(map, const ['type', 'category']);
    final createdAtRaw = _readString(
      map,
      const ['createdAt', 'createdDate', 'timestamp', 'time'],
    );
    final createdAt = createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);
    final id = _readString(map, const ['id', 'publicId', 'notificationId']);

    final read = map['read'];
    final isRead = read is bool
        ? read
        : (map['isRead'] is bool
              ? map['isRead'] as bool
              : (map['readAt'] != null || map['seenAt'] != null));

    return _UiNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead,
    );
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
