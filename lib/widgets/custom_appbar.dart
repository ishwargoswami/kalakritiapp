import 'package:flutter/material.dart';
import 'package:kalakritiapp/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Function? onBackPressed;
  final Color? backgroundColor;
  final Color? titleColor;

  const CustomAppBar({
    Key? key, 
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.titleColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? kPrimaryColor,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                if (onBackPressed != null) {
                  onBackPressed!();
                } else {
                  Navigator.pop(context);
                }
              },
            ) 
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
} 