enum Role { student, admin }

extension RoleApi on Role {
  String toApi() => this == Role.admin ? 'ADMIN' : 'STUDENT';

  static Role fromApi(String value) => value == 'ADMIN' ? Role.admin : Role.student;
}


