import 'package:flutter/material.dart';

class HomeSecreen extends StatelessWidget {
  const HomeSecreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      FloatingActionButton(onPressed: (){
        Navigator.pushNamed(context, '/login');
      }),

    );
  }
}
