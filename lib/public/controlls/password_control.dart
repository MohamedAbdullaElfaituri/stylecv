String? validatePassword(String? value) {
  if (value?.isEmpty ?? true) return 'Please enter your password';
  if (value!.length < 6) return 'Password must be at least 6 characters';
  return null;
}
