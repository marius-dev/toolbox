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
        SizedBox(height: context.compactValue(6)),
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
      ],
    );
  }

  Widget _buildPathRow(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium!.color!;
    final displayPath = StringUtils.replaceHomeWithTilde(project.path);
    final openingText = 'Opening${'.' * ((openingDots % 3) + 1)}';
    final gitInfo = project.gitInfo;

    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPathAppIcon(context, textColor),
          SizedBox(width: context.compactValue(6)),
          Expanded(
            child: isOpening
                ? Text(
                    openingText,
                    style: TextStyle(color: Colors.white, fontSize: 13),
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
          if (!isOpening && !isDisabled && gitInfo.isGitRepo) ...[
            SizedBox(width: context.compactValue(8)),
            _GitInfoBadges(gitInfo: gitInfo, accentColor: accentColor),
          ],
        ],
      ),
    );
  }

  Widget _buildPathAppIcon(BuildContext context, Color mutedText) {
    if (preferredTool == null) {
      return Icon(
        Icons.insert_drive_file_outlined,
        size: context.compactValue(14),
        color: mutedText.withOpacity(0.7),
      );
    }

    return Tooltip(
      message: 'Last opened with ${preferredTool!.name}',
      child: ToolIcon(
        tool: preferredTool!,
        size: context.compactValue(20),
        borderRadius: 4,
      ),
    );
  }
}

class _GitInfoBadges extends StatelessWidget {
  final ProjectGitInfo gitInfo;
  final Color accentColor;

  const _GitInfoBadges({required this.gitInfo, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final branch = gitInfo.branch ?? 'detached';
    final statusLabel = gitInfo.isClean ? null : _buildStatusLabel();

    final branchTooltip = _buildBranchTooltip();
    final statusTooltip = statusLabel == null ? null : _buildStatusTooltip();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GitBadge(
          label: branch,
          icon: Icons.call_split_rounded,
          color: accentColor,
          tooltip: branchTooltip,
          maxWidth: context.compactValue(120),
        ),
        if (statusLabel != null) ...[
          SizedBox(width: context.compactValue(6)),
          _GitBadge(
            label: statusLabel,
            icon: Icons.circle,
            color: Colors.orange,
            tooltip: statusTooltip,
            maxWidth: context.compactValue(110),
          ),
        ],
      ],
    );
  }

  String? _buildBranchTooltip() {
    final parts = <String>[];
    if (gitInfo.origin != null) {
      parts.add('Origin: ${gitInfo.origin}');
    }
    if (gitInfo.rootPath != null) {
      parts.add('Root: ${gitInfo.rootPath}');
    }
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  String? _buildStatusTooltip() {
    final parts = <String>[];

    if (gitInfo.isClean) {
      parts.add('Working tree clean');
    } else {
      parts.add(
        'Changes: ${gitInfo.stagedChanges} staged, '
        '${gitInfo.unstagedChanges} unstaged, '
        '${gitInfo.untrackedChanges} untracked',
      );
    }

    if (gitInfo.ahead != null || gitInfo.behind != null) {
      parts.add('Ahead/behind: ${gitInfo.ahead ?? 0}/${gitInfo.behind ?? 0}');
    }

    if (gitInfo.lastCommitMessage != null) {
      final shortHash = gitInfo.lastCommitHash == null
          ? ''
          : gitInfo.lastCommitHash!.substring(0, 7);
      final summary = shortHash.isEmpty
          ? gitInfo.lastCommitMessage!
          : '$shortHash - ${gitInfo.lastCommitMessage}';
      parts.add('Last commit: $summary');
    }

    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  String _buildStatusLabel() {
    if (gitInfo.isClean) {
      return 'Clean';
    }

    final changeWord = gitInfo.totalChanges == 1 ? 'change' : 'changes';
    return '${_formatChangeCount(gitInfo.totalChanges)} $changeWord';
  }

  static String _formatChangeCount(int value) {
    if (value >= _million) {
      return _formatApproximateLabel(value, _million, 'M');
    }

    if (value >= _thousand) {
      final approxLabel = _formatApproximateLabel(value, _thousand, 'k');
      if (approxLabel == '~1000k') {
        return _formatApproximateLabel(value, _million, 'M');
      }
      return approxLabel;
    }

    return value.toString();
  }

  static String _formatApproximateLabel(int value, int divisor, String suffix) {
    final approx = value / divisor;
    final rounded = (approx * 10).round() / 10;
    final roundedInt = rounded.toInt();
    final isWhole = (rounded - roundedInt).abs() < 0.001;
    final formattedNumber = isWhole
        ? roundedInt.toString()
        : rounded.toStringAsFixed(1);
    return '~$formattedNumber$suffix';
  }

  static const int _thousand = 1000;
  static const int _million = 1000000;
}

class _GitBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? tooltip;
  final double maxWidth;

  const _GitBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.tooltip,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall!;
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.compactValue(6),
        vertical: context.compactValue(2),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(context.compactValue(DesignTokens.radiusSm)),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.compactValue(12), color: color),
          SizedBox(width: context.compactValue(4)),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return content;
    }

    return Tooltip(
      message: tooltip!,
      waitDuration: const Duration(milliseconds: 120),
      child: content,
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
        size: context.compactValue(18),
      ),
      splashRadius: context.compactValue(18),
      padding: EdgeInsets.all(context.compactValue(4)),
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
      context.accentColor,
      context.isDark,
    );
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final avatarSize = context.compactValue(38);
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
        borderRadius: BorderRadius.circular(context.compactValue(DesignTokens.radiusMd)),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              // Subtler shadow - less accent color prominence
              color: accentColor.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: context.compactValue(13),
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
    // Animate height for smoother appearance
    return AnimatedContainer(
      duration: GlassTransitions.stateDuration,
      curve: GlassTransitions.stateCurve,
      width: 3,
      height: isVisible ? 22 : 0, // Slightly shorter
      decoration: BoxDecoration(
        // Subtler accent indicator
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
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
  final midColor = Color.lerp(colors.first, colors.last, 0.5)!.withValues(alpha: 0.9);

  return LinearGradient(
    begin: startAlignment,
    end: endAlignment,
    colors: [colors.first, midColor, colors.last],
    stops: const [0.0, 0.58, 1.0],
  );
}

List<Color> _projectAvatarGradientColors(String name, Color accentColor) {
  final randomColor = _projectAvatarRandomColor(name);
  // Reduced accent mix-in for subtler influence
  final mixedColor = Color.lerp(randomColor, accentColor, 0.20)!;
  return [
    _adjustLightness(randomColor, 0.10),
    _adjustLightness(mixedColor, -0.06),
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
