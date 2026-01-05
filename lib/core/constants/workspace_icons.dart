import 'package:flutter/material.dart';

/// Predefined workspace icons - allows Flutter to tree-shake properly
class WorkspaceIcons {
  WorkspaceIcons._();

  static const int defaultIconIndex = 0;

  static const List<IconData> icons = [
    Icons.layers_rounded, // 0 - Default
    Icons.folder_rounded, // 1
    Icons.code_rounded, // 2
    Icons.terminal_rounded, // 3
    Icons.storage_rounded, // 4
    Icons.cloud_rounded, // 5
    Icons.rocket_launch_rounded, // 6
    Icons.palette_rounded, // 7
    Icons.brush_rounded, // 8
    Icons.camera_alt_rounded, // 9
    Icons.music_note_rounded, // 10
    Icons.video_library_rounded, // 11
    Icons.image_rounded, // 12
    Icons.architecture_rounded, // 13
    Icons.settings_rounded, // 14
    Icons.build_rounded, // 15
    Icons.extension_rounded, // 16
    Icons.api_rounded, // 17
    Icons.web_rounded, // 18
    Icons.phone_android_rounded, // 19
    Icons.laptop_mac_rounded, // 20
    Icons.bug_report_rounded, // 21
    Icons.science_rounded, // 22
    Icons.lightbulb_rounded, // 23
    Icons.star_rounded, // 24
    Icons.favorite_rounded, // 25
    Icons.bookmark_rounded, // 26
    Icons.workspace_premium_rounded, // 27
    Icons.shopping_bag_rounded, // 28
    Icons.school_rounded, // 29
  ];

  static IconData getIcon(int index) {
    if (index < 0 || index >= icons.length) {
      return icons[defaultIconIndex];
    }
    return icons[index];
  }

  static int get iconCount => icons.length;
}
