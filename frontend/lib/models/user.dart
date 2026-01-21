class User {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final Plan? plan;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.plan,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      plan: json['plan'] != null ? Plan.fromJson(json['plan']) : null,
    );
  }
}

class Plan {
  final int id;
  final String name;
  final DateTime? subscriptionEnd;

  Plan({
    required this.id,
    required this.name,
    this.subscriptionEnd,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      name: json['name'],
      subscriptionEnd: json['subscriptionEnd'] != null
          ? DateTime.parse(json['subscriptionEnd'])
          : null,
    );
  }
}
