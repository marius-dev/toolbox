import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'storage_keys.dart';

/// Base class for all storage services providing common file operations.
///
/// This class handles the low-level file I/O operations and path resolution
/// that are shared across all specialized storage services.
abstract class BaseStorageService {
  /// Returns the local application documents directory path.
  Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Returns a File for the given filename in the local directory.
  Future<File> getFile(String filename) async {
    final path = await localPath;
    return File('$path/$filename');
  }

  /// Returns the projects file.
  Future<File> get projectsFile => getFile(StorageKeys.projectsFile);

  /// Returns the workspaces file.
  Future<File> get workspacesFile => getFile(StorageKeys.workspacesFile);

  /// Returns the preferences file.
  Future<File> get preferencesFile => getFile(StorageKeys.preferencesFile);

  /// Reads and returns the preferences JSON as a Map.
  ///
  /// Returns an empty map if the file doesn't exist or can't be read.
  Future<Map<String, dynamic>> readPreferences() async {
    try {
      final file = await preferencesFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final decoded = json.decode(contents);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Error reading preferences: $e');
    }
    return {};
  }

  /// Writes the given data to the preferences file.
  Future<void> writePreferences(Map<String, dynamic> data) async {
    try {
      final file = await preferencesFile;
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  /// Reads a JSON file and returns its contents as a list of maps.
  ///
  /// Returns an empty list if the file doesn't exist or can't be read.
  Future<List<Map<String, dynamic>>> readJsonList(File file) async {
    try {
      if (await file.exists()) {
        final contents = await file.readAsString();
        return List<Map<String, dynamic>>.from(json.decode(contents));
      }
      return [];
    } catch (e) {
      debugPrint('Error reading JSON list from ${file.path}: $e');
      return [];
    }
  }

  /// Writes a list of maps to a JSON file.
  Future<void> writeJsonList(File file, List<Map<String, dynamic>> data) async {
    try {
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error writing JSON list to ${file.path}: $e');
    }
  }
}
