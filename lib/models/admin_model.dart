enum AdminRole { superAdmin, moderator, support, finance }

class AdminModel {
  final String id;
  final String userId;
  final AdminRole role;
  final List<String> permissions;
  final DateTime lastActive;
  final bool isActive;

  AdminModel({
    required this.id,
    required this.userId,
    required this.role,
    this.permissions = const [],
    required this.lastActive,
    this.isActive = true,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      role: AdminRole.values.firstWhere(
        (e) => e.toString() == 'AdminRole.${json['role']}',
      ),
      permissions: List<String>.from(json['permissions'] ?? []),
      lastActive: DateTime.parse(json['lastActive'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'lastActive': lastActive.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Check if admin has specific permission
  bool hasPermission(String permission) {
    if (role == AdminRole.superAdmin) return true;
    return permissions.contains(permission);
  }
}
