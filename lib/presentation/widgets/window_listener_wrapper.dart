import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowListenerWrapper extends StatefulWidget {
  final Widget child;

  const WindowListenerWrapper({Key? key, required this.child})
    : super(key: key);

  @override
  State<WindowListenerWrapper> createState() => _WindowListenerWrapperState();
}

class _WindowListenerWrapperState extends State<WindowListenerWrapper>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowBlur() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      await windowManager.hide();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
