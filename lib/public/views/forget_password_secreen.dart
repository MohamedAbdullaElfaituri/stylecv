import 'package:flutter/material.dart';
import '../controlls/email_control.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Color primaryColor;

  ForgotPasswordScreen({super.key, required this.primaryColor});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: _buildBoxDecoration(),
            child: Material(
              color: Colors.transparent,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 20),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildResetButton(context),
                    const SizedBox(height: 10),
                    _buildCancelButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          spreadRadius: 5,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      "Reset Password",
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: widget.primaryColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        hintText: "Enter your email",
        prefixIcon: Icon(Icons.email, color: widget.primaryColor),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(15),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: validateEmail,
    );
  }


  Widget _buildResetButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 4,
      ),
      onPressed: () => _handleResetPassword(context),
      child: const Text(
        "Send Reset Link",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _handleResetPassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final response = await AuthService()
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.error ??
            'Password reset email sent to ${_emailController.text.trim()}'),
        duration: const Duration(seconds: 5),
      ),
    );

    if (response.error == null) {
      Navigator.pop(context);
    }
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        "Cancel",
        style: TextStyle(
          color: widget.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}