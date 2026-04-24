import 'package:flutter/material.dart';

Widget podCards(String title, List<Widget> body) {
  return Container(
    padding: EdgeInsets.all(20),
    margin: EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.indigo[50],
      borderRadius: BorderRadius.circular(24)
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                  letterSpacing: 1
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.only(top: 24)),
        for (Widget widget in body) widget
      ],
    ),
  );
}