import 'package:flutter/material.dart';
import 'package:kalakritiapp/utils/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;
  final bool isFullWidth;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50.0,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final Color txtColor = textColor ?? (isOutlined ? bgColor : Colors.white);
    final double btnWidth = isFullWidth ? double.infinity : (width ?? 180);
    
    if (isOutlined) {
      return SizedBox(
        width: btnWidth,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: bgColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildButtonContent(txtColor),
        ),
      );
    } else {
      return SizedBox(
        width: btnWidth,
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: txtColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 2,
          ),
          child: _buildButtonContent(txtColor),
        ),
      );
    }
  }

  Widget _buildButtonContent(Color txtColor) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(txtColor),
        ),
      );
    }

    // If we have custom leading/trailing widgets
    if (leadingIcon != null || trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon!,
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            trailingIcon!,
          ],
        ],
      );
    }

    // If we have an icon
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // Simple text button
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
} 