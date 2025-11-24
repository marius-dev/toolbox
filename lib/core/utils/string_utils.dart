class StringUtils {
  static String ellipsisStart(String value, {int maxLength = 40}) {
    if (value.length <= maxLength) return value;
    final keep = maxLength - 3;
    return '...${value.substring(value.length - keep)}';
  }
}
