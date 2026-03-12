class User {
  final int id;
  final String username;
  final String role;

  User({required this.id, required this.username, required this.role});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(id: map['id'], username: map['username'], role: map['role']);
  }
}
