List<String> parseRoles(dynamic roleField) {
  if (roleField == null) return const [];

  if (roleField is List) {
    return roleField
        .where((e) => e != null)
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  final roleString = roleField.toString().trim();
  if (roleString.isEmpty) return const [];

  // Support legacy single-role string, or comma-separated roles.
  if (roleString.contains(',')) {
    return roleString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  return <String>[roleString];
}

List<String> userRolesFromUserMap(Map<String, dynamic>? user) {
  if (user == null) return const [];
  return parseRoles(user['role']);
}

bool userHasRole(Map<String, dynamic>? user, String role) {
  final roles = userRolesFromUserMap(user);
  final normalized = role.trim();
  return roles.any((r) => r == normalized);
}

bool userHasAnyRole(Map<String, dynamic>? user, Set<String> roles) {
  final userRoles = userRolesFromUserMap(user);
  return userRoles.any((r) => roles.contains(r));
}

String formatUserRoles(Map<String, dynamic>? user, {String fallback = ''}) {
  final roles = userRolesFromUserMap(user);
  if (roles.isEmpty) return fallback;
  return roles.join(', ');
}
