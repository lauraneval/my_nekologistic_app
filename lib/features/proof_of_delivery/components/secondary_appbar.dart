import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

AppBar secondaryAppbar() {
  return AppBar(
    automaticallyImplyLeading: false,
    title: IconButton(
        onPressed: () {
          print('Logo Clicked');
        },
        icon: SvgPicture.asset(
            'assets/icons/neko_logistic_icon.svg'
        )
    ),
    surfaceTintColor: Colors.white,
    backgroundColor: Colors.white,
    shadowColor: Colors.black12,
    actions: [
      IconButton(
          onPressed: () {
            print('Notification Clicked');
          },
          icon: Icon(
            Icons.notifications_outlined,
            size: 32,
          )
      ),
    ],
  );
}