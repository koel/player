class User {
  int id;
  String name;
  String email;
  bool isAdmin;

  User(this.id, this.name, this.email, this.isAdmin);

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      json['id'],
      json['name'],
      json['email'],
      json['is_admin'],
    );
  }
}
