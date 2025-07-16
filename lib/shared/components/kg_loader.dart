import 'package:flutter/material.dart';

class KGLoader extends StatefulWidget {
  const KGLoader({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<KGLoader> createState() => _ElLoaderState();
}

class _ElLoaderState extends State<KGLoader> {

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? MediaQuery.of(context).size.height * 0.4,
      width: widget.width ?? MediaQuery.of(context).size.width,
      child: Center(
        child: Text("Loader"),
      ),
    );
  }
}
