class MapConfig {
  // CartoDB — completely free, no API key, no account needed.
  // Voyager: crisp day style with buildings, roads, labels.
  // Dark All: clean dark style for night / navigation.
  static const String _voyager =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const String _darkAll =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static const List<String> subdomains = ['a', 'b', 'c', 'd'];

  static String tileUrl({required bool dark}) => dark ? _darkAll : _voyager;
}
