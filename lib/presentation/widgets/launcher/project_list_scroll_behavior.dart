import 'package:flutter/material.dart';

class ProjectListScrollBehavior extends ScrollBehavior {
  const ProjectListScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
