import 'package:flutter/material.dart';
import 'package:kalakritiapp/utils/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double borderRadius;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius = 12,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ?? kPrimaryColor;
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            disabledBackgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: _buildButtonContent(txtColor),
        ),
      );
    }
  }

  Widget _buildButtonContent(Color txtColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(txtColor),
        ),
      );
    }
    
    // If we have custom leading/trailing widgets
    if (leadingIcon != null || trailingIcon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon!,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            trailingIcon!,
          ],
        ],
      );
    }
    
    // If we have an icon from IconData
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    
    // Simple text button
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    );
  }
} 