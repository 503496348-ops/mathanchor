class UserProfile {
  String nickname;
  String avatar;
  String grade;
  String bio;

  UserProfile({
    this.nickname = '用户昵称',
    this.avatar = '',
    this.grade = 'Math Explorer',
    this.bio = '',
  });

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'avatar': avatar,
        'grade': grade,
        'bio': bio,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        nickname: json['nickname'] as String? ?? '用户昵称',
        avatar: json['avatar'] as String? ?? '',
        grade: json['grade'] as String? ?? 'Math Explorer',
        bio: json['bio'] as String? ?? '',
      );

  UserProfile copyWith({
    String? nickname,
    String? avatar,
    String? grade,
    String? bio,
  }) =>
      UserProfile(
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        grade: grade ?? this.grade,
        bio: bio ?? this.bio,
      );
}
