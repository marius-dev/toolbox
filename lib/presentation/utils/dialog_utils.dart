import 'package:flutter/material.dart';
import '../../core/theme/theme_colors.dart';

/// Centralized dialog utilities to eliminate duplication and enforce consistency.
///
/// This class provides helper methods for showing dialogs with consistent styling
/// following the DRY principle.
class DialogUtils {
  DialogUtils._();

  /// Shows a dialog with the app's default barrier color.
  ///
  /// Uses a consistent barrier color (black with 78% opacity) across all dialogs.
  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? ThemeColors.dialogBarrierColor(),
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  /// Shows a confirmation dialog with Yes/No buttons.
  ///
  /// Returns true if user confirms, false if user cancels, null if dismissed.
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Yes',
    String cancelLabel = 'No',
    bool isDangerous = false,
  }) {
    return showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Shows a simple message dialog with an OK button.
  ///
  /// Returns when the user dismisses the dialog.
  static Future<void> showMessageDialog({
    required BuildContext context,
    required String title,
    required String message,
    String okLabel = 'OK',
  }) {
    return showAppDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(okLabel),
          ),
        ],
      ),
    );
  }

  /// Shows an error dialog with a consistent error styling.
  ///
  /// Returns when the user dismisses the dialog.
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String okLabel = 'OK',
  }) {
    return showAppDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(okLabel),
          ),
        ],
      ),
    );
  }
}
