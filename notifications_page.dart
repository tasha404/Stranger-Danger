// pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'ios_notification_banner.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String type;
  final String? location;
  final String? person;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.location,
    this.person,
    this.isRead = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> notifications = [
    NotificationItem(
      id: '1',
      title: 'Unauthorized Face Detected',
      message: 'Unknown person detected',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      type: 'unauthorized',
      location: 'Front Door',
    ),
    NotificationItem(
      id: '2',
      title: 'Motion Detected',
      message: 'Movement detected',
      time: DateTime.now().subtract(const Duration(minutes: 15)),
      type: 'motion',
      location: 'Living Room',
    ),
    NotificationItem(
      id: '3',
      title: 'Authorized Entry',
      message: 'Family member entered',
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      type: 'authorized',
      person: 'Alice Smith',
    ),
    NotificationItem(
      id: '4',
      title: 'Unauthorized Face Detected',
      message: 'Unknown person in backyard',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'unauthorized',
      location: 'Backyard',
    ),
  ];

  void _dismissNotification(String id) {
    setState(() {
      notifications.removeWhere((notification) => notification.id == id);
    });
    
    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification dismissed'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // You'd need to implement undo logic
          },
        ),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will remove all notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              setState(() => notifications.clear());
              Navigator.pop(context);
            },
            child: const Text(
              'CLEAR ALL',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner(NotificationItem notification) {
    switch (notification.type) {
      case 'unauthorized':
        return UnauthorizedFaceBanner(
          location: notification.location ?? 'Unknown location',
          time: _getTimeAgo(notification.time),
          onTap: () {
            setState(() {
              notification.isRead = true;
            });
            // You could navigate to camera feed or details page
          },
        );
      case 'motion':
        return MotionDetectedBanner(
          location: notification.location ?? 'Unknown location',
          time: _getTimeAgo(notification.time),
          onTap: () {
            setState(() {
              notification.isRead = true;
            });
          },
        );
      case 'authorized':
        return AuthorizedEntryBanner(
          person: notification.person ?? 'Family Member',
          time: _getTimeAgo(notification.time),
          onTap: () {
            setState(() {
              notification.isRead = true;
            });
          },
        );
      default:
        return IOSNotificationBanner(
          title: notification.title,
          message: '${notification.message} • ${_getTimeAgo(notification.time)}',
          icon: Icons.notifications,
          color: const Color(0xFF3498DB), // Blue
          onTap: () {
            setState(() {
              notification.isRead = true;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 255, 207, 242).withOpacity(0.9),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: notifications.isNotEmpty ? _clearAll : null,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F5F7),
              Color(0xFFF0F0F0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Header with stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${notifications.length} Notifications',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${notifications.where((n) => !n.isRead).length} unread',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Mark All Read'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),

            // iOS-style banners
            Expanded(
              child: notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_rounded,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Notifications',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Security alerts will appear here',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        
                        return Dismissible(
                          key: Key(notification.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          onDismissed: (_) => _dismissNotification(notification.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: _buildNotificationBanner(notification),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${difference.inDays ~/ 7}w ago';
  }
}