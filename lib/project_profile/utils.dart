import 'dart:io';

class SizedPath {
  final String path;
  final int sizeBytes;
  SizedPath(this.path, this.sizeBytes);
}

String nameOf(String path) =>
    path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last;

String extOf(String name) {
  final i = name.lastIndexOf('.');
  if (i <= 0 || i == name.length - 1) return '';
  return name.substring(i).toLowerCase();
}

void trackLargeFile(List<SizedPath> list, SizedPath item, {required int keep}) {
  list.add(item);
  list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  if (list.length > keep) {
    list.removeRange(keep, list.length);
  }
}

Map<String, int> sortedMapByValueDesc(Map<String, int> m) {
  final entries = m.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final out = <String, int>{};
  for (final e in entries) {
    out[e.key] = e.value;
  }
  return out;
}

String slugify(String s) {
  final lower = s.toLowerCase();
  final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return cleaned
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String relPath(String root, String full) {
  final rp = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  if (full.startsWith(rp)) {
    return full.substring(rp.length).replaceAll('\\', '/');
  }
  return full.replaceAll('\\', '/');
}
