import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  final bool withUnderline;
  final double fontSize;
  final FontWeight fontWeight;

  const SectionHeader({
    Key? key,
    required this.title,
    this.textColor = const Color(0xff142831),
    this.withUnderline = false,
    this.fontSize = 24.0,
    this.fontWeight = FontWeight.w700,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
              letterSpacing: 0.8,
              shadows: [
                Shadow(
                  color: textColor.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
          if (withUnderline)
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 3,
              width: 50,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    textColor,
                    textColor.withOpacity(0.5),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}