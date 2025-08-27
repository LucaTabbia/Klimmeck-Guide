import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({super.key, required this.child, this.size});

  final Widget child;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: size ?? MediaQuery.of(context).size.width,
          height: size ?? MediaQuery.of(context).size.height,
          child: Image.asset('assets/images/menu/menuBackground.png', fit: BoxFit.cover),
        ),
        child,
      ],
    );
  }
}
