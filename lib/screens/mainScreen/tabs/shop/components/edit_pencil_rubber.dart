import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditPencilRubber extends StatelessWidget {
  final bool? isAdd;
  final Function(bool? newIsAdd) onToggle;

  const EditPencilRubber({
    super.key,
    required this.isAdd,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          bottom: 150,
          left: isAdd == true ? 0 : -80,
          child: GestureDetector(
            onTap: () {
              final newIsAdd = isAdd == true ? null : true;
              onToggle(newIsAdd);
            },
            child: SizedBox(
              height: 150,
              child: RotatedBox(
                quarterTurns: 1,
                child: SvgPicture.network(
                  "https://res.cloudinary.com/dzuhywp53/image/upload/v1761320846/pencil_wpysez.svg",
                  height: 150,
                ),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          bottom: 0,
          left: isAdd == false ? 0 : -80,
          child: GestureDetector(
            onTap: () {
              final newIsAdd = isAdd == false ? null : false;
              onToggle(newIsAdd);
            },
            child: SizedBox(
              height: 150,
              child: RotatedBox(
                quarterTurns: 1,
                child: SvgPicture.network(
                  "https://res.cloudinary.com/dzuhywp53/image/upload/v1761320949/rubber_bnonlz.svg",
                  height: 150,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
