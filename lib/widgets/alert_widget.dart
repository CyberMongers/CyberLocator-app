import 'package:flutter/material.dart';

Widget alertBox(bool isVisible) {
  return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
      height: isVisible ? 100 : 0,
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Spacer(),
          Image.asset("assets/siren.gif", height: 50, fit: BoxFit.contain),
          const SizedBox(
            width: 30,
          ),
          const Text("Please return to the safe zone!",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const Spacer()
        ],
      ));
}
