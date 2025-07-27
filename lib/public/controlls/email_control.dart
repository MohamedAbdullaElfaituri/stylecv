String? validateEmail(String? value) {
  if (value?.isEmpty ?? true) return 'Please enter your email';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
    return 'Please enter a valid email';
  }
  return null;
}
