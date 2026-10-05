import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _allNotifications = [
    {
      'id': 'notif-1',
      'type': 'message',
      'title': 'Aria Vance Studio',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      'content': 'I uploaded the 3D lighting layout for the living room makeover!',
      'time': '10:42 AM',
      'unread': true,
      'status': 'Active Proposal',
      'icon': Icons.chat_bubble_outline_rounded,
    },
    {
      'id': 'notif-2',
      'type': 'quote',
      'title': 'Quote Update: Modern Japandi Suite',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      'content': 'Julian Thorne updated the custom cabinetry line item with a 10% atelier discount.',
      'time': '1 hr ago',
      'unread': true,
      'status': 'Quote Ready',
      'icon': Icons.receipt_long_outlined,
    },
    {
      'id': 'notif-3',
      'type': 'message',
      'title': 'Marcus Sterling Interiors',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      'content': 'Sample swatches have arrived. Ready for your review.',
      'time': 'Yesterday',
      'unread': false,
      'status': 'In Progress',
      'icon': Icons.chat_bubble_outline_rounded,
    },
    {
      'id': 'notif-4',
      'type': 'project',
      'title': 'Milestone 2 Completed',
      'avatar': 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=200&q=80',
      'content': 'Rough-in electrical and ceiling cove plastering finished for penthouse project.',
      'time': '2 days ago',
      'unread': false,
      'status': 'Milestone Ready',
      'icon': Icons.account_tree_outlined,
    },
    {
      'id': 'notif-5',
      'type': 'message',
      'title': 'Elena Rostova Atelier',
      'avatar': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=80',
      'content': 'Thank you! Contract terms confirmed for the dining room styling.',
      'time': 'Sep 28',
      'unread': false,
      'status': 'Completed',
      'icon': Icons.chat_bubble_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markAllAsRead() {
    setState(() {
      for (final item in _allNotifications) {
        item['unread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications & messages marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFD48270) : const Color(0xFF8C4A3E);
    final cardBg = isDark ? const Color(0xFF1A1715) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2824) : const Color(0xFFEFE7DE);
    final subtitleColor = isDark ? const Color(0xFFB5A49B) : const Color(0xFF7A6B65);

    final messageNotifications =
        _allNotifications.where((n) => n['type'] == 'message').toList();
    final updateNotifications =
        _allNotifications.where((n) => n['type'] != 'message').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications & Messages',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, size: 20),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: subtitleColor,
          indicatorColor: primaryColor,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Messages'),
            Tab(text: 'Updates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_allNotifications, isDark, cardBg, borderColor, primaryColor, subtitleColor),
          _buildNotificationList(messageNotifications, isDark, cardBg, borderColor, primaryColor, subtitleColor),
          _buildNotificationList(updateNotifications, isDark, cardBg, borderColor, primaryColor, subtitleColor),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    List<Map<String, dynamic>> items,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color subtitleColor,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 56, color: subtitleColor.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              'No notifications in this tab',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: subtitleColor),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isUnread = item['unread'] == true;
        final bool isMessage = item['type'] == 'message';

        return Container(
          decoration: BoxDecoration(
            color: isUnread
                ? (isDark ? const Color(0xFF2E221E) : const Color(0xFFFBF8F3))
                : cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? primaryColor.withValues(alpha: 0.35) : borderColor,
              width: isUnread ? 1.4 : 1.0,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(item['avatar'] as String),
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1A1715) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item['time'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUnread ? primaryColor : subtitleColor,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  item['content'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread
                        ? (isDark ? Colors.white : const Color(0xFF241611))
                        : subtitleColor,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1613) : const Color(0xFFF5EFE8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['status'] as String,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isMessage ? Icons.chat_bubble_outline_rounded : Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: subtitleColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              setState(() {
                item['unread'] = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isMessage
                        ? 'Opening consultation with ${item['title']}'
                        : 'Opening ${item['title']}',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
