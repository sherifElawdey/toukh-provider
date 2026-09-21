import 'package:flutter/material.dart';

import '../icons/toukh_icons.dart';

enum _InboxMenuAction { markAllRead, clearAll, toggleUnreadOnly }

/// Overflow menu for notification inbox screens (mark all read, clear, unread filter).
class ToukhNotificationInboxMenuButton extends StatelessWidget {
  const ToukhNotificationInboxMenuButton({
    super.key,
    required this.showUnreadOnly,
    required this.markAllReadLabel,
    required this.clearAllLabel,
    required this.showUnreadOnlyLabel,
    required this.onMarkAllRead,
    required this.onClearAll,
    required this.onToggleUnreadOnly,
  });

  final bool showUnreadOnly;
  final String markAllReadLabel;
  final String clearAllLabel;
  final String showUnreadOnlyLabel;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;
  final VoidCallback onToggleUnreadOnly;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_InboxMenuAction>(
      icon: Icon(ToukhIcons.moreVertical),
      onSelected: (action) {
        switch (action) {
          case _InboxMenuAction.markAllRead:
            onMarkAllRead();
          case _InboxMenuAction.clearAll:
            onClearAll();
          case _InboxMenuAction.toggleUnreadOnly:
            onToggleUnreadOnly();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _InboxMenuAction.markAllRead,
          child: Text(markAllReadLabel),
        ),
        PopupMenuItem(
          value: _InboxMenuAction.clearAll,
          child: Text(clearAllLabel),
        ),
        PopupMenuItem(
          value: _InboxMenuAction.toggleUnreadOnly,
          child: Row(
            children: [
              if (showUnreadOnly)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check, size: 18),
                ),
              Expanded(child: Text(showUnreadOnlyLabel)),
            ],
          ),
        ),
      ],
    );
  }
}
