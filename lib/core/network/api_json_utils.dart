/// Helpers to parse inconsistent API JSON shapes.
abstract final class ApiJsonUtils {
  static List<Map<String, dynamic>> extractList(
    dynamic data, {
    List<String> keys = const [
      'data',
      'items',
      'posts',
      'accounts',
      'boards',
      'pages',
      'channels',
      'profiles',
      'results',
    ],
  }) {
    if (data == null) return [];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in keys) {
        final v = map[key];
        if (v is List) {
          return v
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return [map];
    }
    return [];
  }

  static String? readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (!key.contains('.')) {
        final v = map[key];
        if (v != null && v.toString().isNotEmpty) return v.toString();
        continue;
      }
      dynamic cur = map;
      for (final part in key.split('.')) {
        if (cur is Map && cur.containsKey(part)) {
          cur = cur[part];
        } else {
          cur = null;
          break;
        }
      }
      if (cur != null && cur.toString().isNotEmpty) return cur.toString();
    }
    return null;
  }
}
