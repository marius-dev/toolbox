part of 'project_item.dart';

class _MenuPositioner {
  static Rect calculateMenuRect({
    required BuildContext context,
    required Rect anchorRect,
    required Size overlaySize,
    required double menuWidth,
    required double menuHeight,
  }) {
    final horizontalPadding = context.compactValue(8);
    final horizontalOffset = -context.compactValue(6);
    final verticalOffset = context.compactValue(10);

    final desiredLeft = anchorRect.left + horizontalOffset;
    final left = math.min(
      overlaySize.width - menuWidth - horizontalPadding,
      math.max(horizontalPadding, desiredLeft),
    );

    final spaceBelow = overlaySize.height - anchorRect.bottom;
    final shouldShowAbove =
        menuHeight + verticalOffset > spaceBelow && anchorRect.top > menuHeight;

    final top = shouldShowAbove
        ? math.max(
            horizontalPadding,
            anchorRect.top - menuHeight - verticalOffset,
          )
        : math.min(
            overlaySize.height - menuHeight - horizontalPadding,
            anchorRect.bottom + verticalOffset,
          );

    return Rect.fromLTWH(left, top, menuWidth, menuHeight);
  }
}

void _noop() {}
