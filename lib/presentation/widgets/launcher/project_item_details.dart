part of 'project_item.dart';

class _ProjectDetails extends StatelessWidget {
  final Project project;
  final Tool? preferredTool;
  final String searchQuery;
  final bool revealFullPath;
  final bool isOpening;
  final int openingDots;
  final bool isDisabled;
  final Color accentColor;

  const _ProjectDetails({
    required this.project,
    required this.preferredTool,
    required this.searchQuery,
    required this.revealFullPath,
    required this.isOpening,
    required this.openingDots,
    required this.isDisabled,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(context),
        SizedBox(height: CompactLayout.value(context, 6)),
        _buildPathRow(context),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge!.color!;
    final muted = textColor.withOpacity(0.75);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: _highlightMatches(
                project.name,
                searchQuery,
                TextStyle(
                  color: isDisabled ? muted.withOpacity(0.6) : textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                TextStyle(color: accentColor, fontWeight: FontWeight.w700),
              ),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isDisabled) ...[
          SizedBox(width: CompactLayout.value(context, 6)),
          _MissingPathBadge(),
        ],
      ],
    );
  }

  Widget _buildPathRow(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium!.color!;
    final displayPath = StringUtils.replaceHomeWithTilde(project.path);
    final openingText = 'Opening${'.' * ((openingDots % 3) + 1)}';

    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPathAppIcon(context, textColor),
          SizedBox(width: CompactLayout.value(context, 6)),
          Expanded(
            child: isOpening
                ? Text(
                    openingText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  )
                : Text.rich(
                    TextSpan(
                      children: _highlightMatches(
                        displayPath,
                        searchQuery,
                        TextStyle(
                          color: isDisabled
                              ? textColor.withOpacity(0.4)
                              : textColor.withOpacity(0.85),
                          fontSize: 13,
                        ),
                        TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    maxLines: revealFullPath ? 3 : 1,
                    overflow: revealFullPath
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    softWrap: revealFullPath,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathAppIcon(BuildContext context, Color mutedText) {
    if (preferredTool == null) {
      return Icon(
        Icons.insert_drive_file_outlined,
        size: CompactLayout.value(context, 14),
        color: mutedText.withOpacity(0.7),
      );
    }

    return Tooltip(
      message: 'Last opened with ${preferredTool!.name}',
      child: ToolIcon(
        tool: preferredTool!,
        size: CompactLayout.value(context, 20),
        borderRadius: 4,
      ),
    );
  }
}

class _MissingPathBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: CompactLayout.value(context, 6),
        vertical: CompactLayout.value(context, 2),
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: CompactLayout.value(context, 12),
            color: Colors.red,
          ),
          SizedBox(width: CompactLayout.value(context, 4)),
          Text(
            'Path missing',
            style: TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  final bool isStarred;
  final VoidCallback onPressed;
  final Color accentColor;

  const _StarButton({
    required this.isStarred,
    required this.onPressed,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isStarred
        ? accentColor
        : Theme.of(context).iconTheme.color!.withOpacity(0.75);

    return IconButton(
      tooltip: isStarred ? 'Remove favorite' : 'Mark favorite',
      icon: Icon(
        isStarred ? Icons.star_rounded : Icons.star_border_rounded,
        color: iconColor,
        size: CompactLayout.value(context, 18),
      ),
      splashRadius: CompactLayout.value(context, 18),
      padding: EdgeInsets.all(CompactLayout.value(context, 4)),
      onPressed: onPressed,
    );
  }
}

class _ProjectAvatar extends StatelessWidget {
  final Project project;
  final bool isDisabled;

  const _ProjectAvatar({required this.project, required this.isDisabled});

  @override
  Widget build(BuildContext context) {
    final accentColor = _softAccentColor(
      ThemeProvider.instance.accentColor,
      Theme.of(context).brightness == Brightness.dark,
    );
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final avatarSize = CompactLayout.value(context, 38);
    final gradient = _projectAvatarGradient(project.name, accentColor);
    final name = project.name.trim();
    final initials = name.isEmpty
        ? '?'
        : name.length == 1
        ? name.toUpperCase()
        : name.substring(0, 2).toUpperCase();

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade700],
              )
            : gradient,
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 10)),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: accentColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: CompactLayout.value(context, 13),
        ),
      ),
    );
  }
}

class _LeftAccent extends StatelessWidget {
  final bool isVisible;
  final Color color;

  const _LeftAccent({required this.isVisible, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: Container(
        width: 3,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

List<TextSpan> _highlightMatches(
  String value,
  String query,
  TextStyle baseStyle,
  TextStyle highlightStyle,
) {
  if (query.isEmpty) {
    return [TextSpan(text: value, style: baseStyle)];
  }

  final lowerValue = value.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;

  while (true) {
    final index = lowerValue.indexOf(lowerQuery, start);
    if (index < 0) {
      spans.add(TextSpan(text: value.substring(start), style: baseStyle));
      break;
    }
    if (index > start) {
      spans.add(
        TextSpan(text: value.substring(start, index), style: baseStyle),
      );
    }
    spans.add(
      TextSpan(
        text: value.substring(index, index + lowerQuery.length),
        style: highlightStyle,
      ),
    );
    start = index + lowerQuery.length;
  }

  return spans;
}

Gradient _projectAvatarGradient(String name, Color accentColor) {
  final colors = _projectAvatarGradientColors(name, accentColor);
  final angle = (name.hashCode % 360) * (math.pi / 180);
  final startAlignment = Alignment(math.cos(angle), math.sin(angle));
  final endAlignment = Alignment(-startAlignment.x, -startAlignment.y);
  final midColor = Color.lerp(colors.first, colors.last, 0.5)!.withOpacity(0.9);

  return LinearGradient(
    begin: startAlignment,
    end: endAlignment,
    colors: [colors.first, midColor, colors.last],
    stops: const [0.0, 0.58, 1.0],
  );
}

List<Color> _projectAvatarGradientColors(String name, Color accentColor) {
  final randomColor = _projectAvatarRandomColor(name);
  final mixedColor = Color.lerp(randomColor, accentColor, 0.35)!;
  return [
    _adjustLightness(randomColor, 0.12),
    _adjustLightness(mixedColor, -0.08),
  ];
}

Color _projectAvatarRandomColor(String name) {
  final hash = name.hashCode & 0x7fffffff;
  final hue = (hash % 360).toDouble();
  final saturation = (0.55 + ((hash >> 8) % 40) / 100).clamp(0.5, 0.95);
  final lightness = (0.38 + ((hash >> 14) % 35) / 100).clamp(0.3, 0.75);
  return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
}

Color _adjustLightness(Color color, double delta) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();
}

Color _softAccentColor(Color color, bool isDarkMode) {
  if (!isDarkMode) return color;
  return Color.lerp(color, Colors.white, 0.3)!;
}
