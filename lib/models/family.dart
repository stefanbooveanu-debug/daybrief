import 'package:flutter/material.dart';

class FamilyInfo {
  const FamilyInfo({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.memberIds,
  });

  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final List<String> memberIds;

  factory FamilyInfo.fromMap(String id, Map<String, dynamic> data) {
    return FamilyInfo(
      id: id,
      name: data['name'] as String? ?? 'Family',
      ownerId: data['ownerId'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      memberIds: (data['memberIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class FamilyMember {
  const FamilyMember({
    required this.uid,
    required this.displayName,
    required this.avatar,
    required this.colorValue,
    required this.role,
  });

  final String uid;
  final String displayName;
  final String avatar;
  final int colorValue;
  final String role;

  Color get color => Color(colorValue);

  factory FamilyMember.fromMap(String uid, Map<String, dynamic> data) {
    return FamilyMember(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Member',
      avatar: data['avatar'] as String? ?? '👤',
      colorValue: (data['color'] as num?)?.toInt() ?? 0xFF1A73E8,
      role: data['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'avatar': avatar,
        'color': colorValue,
        'role': role,
      };
}
