class AdminConfig {
  static const adminEmails = {
    'an2mouth@yahoo.com',
    'alerttmenow@gmail.com',
  };

  static bool isAdmin(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.trim().toLowerCase());
  }
}
