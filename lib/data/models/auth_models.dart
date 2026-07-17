class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.timezone,
    required this.phone,
  });

  final String name;
  final String email;
  final String password;
  final String timezone;
  final String phone;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'timezone': timezone,
        'phone': phone,
      };
}

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class AuthResult {
  const AuthResult({
    required this.message,
    this.token,
    this.email,
    this.name,
  });

  final String message;
  final String? token;
  final String? email;
  final String? name;
}
