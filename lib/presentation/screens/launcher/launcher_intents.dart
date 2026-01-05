import 'package:flutter/widgets.dart';

class TogglePreferencesIntent extends Intent {
  const TogglePreferencesIntent();
}

class AddProjectIntent extends Intent {
  const AddProjectIntent();
}

class CloseWindowIntent extends Intent {
  const CloseWindowIntent();
}

class SwitchWorkspaceIntent extends Intent {
  final int index;
  const SwitchWorkspaceIntent(this.index);
}

class CreateWorkspaceIntent extends Intent {
  const CreateWorkspaceIntent();
}

class DeleteWorkspaceIntent extends Intent {
  const DeleteWorkspaceIntent();
}
