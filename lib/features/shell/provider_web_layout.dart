import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Wide-browser layout for the provider shell.
///
/// Phone, tablet, and a narrow browser keep the bottom navigation.
/// A web window at least [wideMinWidth] uses the sidebar.
abstract final class ProviderWebLayout {
  static const double wideMinWidth = 1024;
  static const double sidebarWidth = 272;

  /// Content pane width at which the home dashboard uses columns.
  /// Just above [wideMinWidth] the pane beside the sidebar is still tight.
  static const double dashboardColumnsMinWidth = 840;

  static bool isWide(BuildContext context) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= wideMinWidth;
  }
}
