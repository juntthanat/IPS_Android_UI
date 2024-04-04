import 'package:flutter/material.dart';

class NavigationArrow extends StatelessWidget {
  const NavigationArrow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 75.0,
        height: 75.0,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            )),
        child: const Icon(
          Icons.arrow_downward,
          color: Colors.white,
          size: 48.0,
        ),
    );
  }
}
