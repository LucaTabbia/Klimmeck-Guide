import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/kg_theme.dart';

class Dropdown extends StatefulWidget {
  const Dropdown({super.key, required this.sectionName, required this.data});

  final String sectionName;
  final Widget data;

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  bool _isOpen = false;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => {
                setState(() {
                  _isOpen = !_isOpen;
                }),
                if (_isOpen) {animationController.forward()} else {animationController.reverse()},
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: maxWidth - (maxWidth / 5),
                      child: AutoSizeText(
                        widget.sectionName,
                        maxFontSize: 20,
                        minFontSize: 12,
                        style: KlimmeckGuideTheme.instance.titleMedium,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        return RotationTransition(
                          turns: Tween<double>(begin: 0, end: 0.5).animate(
                            CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
                          ),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: SvgPicture.asset("assets/icons/svg/arrowDown.svg"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: maxWidth - (maxWidth / 5),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: KlimmeckGuideTheme.darkBronze, width: 1)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
              child: AnimatedSize(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: _isOpen ? BoxConstraints() : BoxConstraints(maxHeight: 0),
                  child: ClipRect(child: widget.data),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
