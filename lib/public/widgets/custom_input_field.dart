import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? value;
  final Function(String) onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;

  // Renk teması
  final Color primaryColor;
  final Color textColor;
  final Color hintColor;
  final Color backgroundColor;
  final Color errorColor;
  final Color borderColor;
  final double borderRadius;

  const CustomInputField({
    Key? key,
    required this.label,
    this.hintText,
    this.value,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
    this.primaryColor = const Color(0xff142831),
    this.textColor = Colors.black87,
    this.hintColor = Colors.grey,
    this.backgroundColor = Colors.white,
    this.errorColor = Colors.red,
    this.borderColor = Colors.grey,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RichText(
                text: TextSpan(
                  text: label,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  children: [
                    if (required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              )),
        TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: backgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: primaryColor, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: errorColor, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: errorColor, width: 2.0),
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            errorStyle: TextStyle(
              color: errorColor,
              fontSize: 12,
            ),
          ),
          validator: required
              ? (v) => v == null || v.isEmpty ? '$label is required' : null
              : validator,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}