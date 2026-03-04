import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/responsive_config.dart';

/// Custom Can Can Branded Components
/// Following the official Can Can Design Guidelines

class CanCanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool showShadow;
  final double? minWidth;
  final double? minHeight;

  const CanCanCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.showShadow = true,
    this.minWidth,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveMargin = margin ?? EdgeInsets.symmetric(
      horizontal: ResponsiveConfig.md,
      vertical: ResponsiveConfig.sm,
    );

    final responsivePadding = padding ?? EdgeInsets.all(ResponsiveConfig.md);

    final responsiveRadius = borderRadius ?? BorderRadius.circular(ResponsiveConfig.radiusLarge);

    final responsiveElevation = showShadow ? (elevation ?? 2.0) : 0.0;

    return Container(
      margin: responsiveMargin,
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0,
        minHeight: minHeight ?? ResponsiveConfig.cardMinHeight,
      ),
      child: Material(
        elevation: responsiveElevation,
        borderRadius: responsiveRadius,
        color: backgroundColor ?? AppTheme.surfaceLight,
        shadowColor: showShadow ? Colors.black.withOpacity(0.1) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: responsiveRadius,
          child: Container(
            padding: responsivePadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class CanCanButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isSecondary;
  final bool isSmall;
  final IconData? icon;
  final double? width;
  final double? height;
  final ButtonSize? size;

  const CanCanButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.isSecondary = false,
    this.isSmall = false,
    this.icon,
    this.width,
    this.height,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? (isSmall ? ButtonSize.small : ButtonSize.medium);
    final responsiveWidth = width ?? (ResponsiveConfig.isTablet ? 300.w : double.infinity);
    final responsiveHeight = height ?? buttonSize.height;

    final iconSize = buttonSize.iconSize;
    final fontSize = buttonSize.fontSize;
    final horizontalPadding = buttonSize.horizontalPadding;

    final Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: iconSize,
            color: isOutlined
              ? (isSecondary ? AppTheme.infoColor : AppTheme.primaryGreen)
              : Colors.white,
          ),
          SizedBox(width: ResponsiveConfig.sm),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: isOutlined
                ? (isSecondary ? AppTheme.infoColor : AppTheme.primaryGreen)
                : Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final borderRadius = BorderRadius.circular(ResponsiveConfig.radiusMedium);

    if (isOutlined) {
      return SizedBox(
        width: responsiveWidth,
        height: responsiveHeight,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isSecondary ? AppTheme.infoColor : AppTheme.primaryGreen,
              width: 2,
            ),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: ResponsiveConfig.sm),
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      width: responsiveWidth,
      height: responsiveHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? AppTheme.infoColor : AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: (isSecondary ? AppTheme.infoColor : AppTheme.primaryGreen).withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: ResponsiveConfig.sm),
        ),
        child: buttonChild,
      ),
    );
  }
}

enum ButtonSize {
  small,
  medium,
  large,
}

extension ButtonSizeExtension on ButtonSize {
  double get height {
    switch (this) {
      case ButtonSize.small:
        return 36.rs;
      case ButtonSize.medium:
        return ResponsiveConfig.buttonHeight;
      case ButtonSize.large:
        return 56.rs;
    }
  }

  double get iconSize {
    switch (this) {
      case ButtonSize.small:
        return ResponsiveConfig.iconSm;
      case ButtonSize.medium:
        return ResponsiveConfig.iconMd;
      case ButtonSize.large:
        return ResponsiveConfig.iconLg;
    }
  }

  double get fontSize {
    switch (this) {
      case ButtonSize.small:
        return ResponsiveConfig.fontSm;
      case ButtonSize.medium:
        return ResponsiveConfig.fontMd;
      case ButtonSize.large:
        return ResponsiveConfig.fontLg;
    }
  }

  double get horizontalPadding {
    switch (this) {
      case ButtonSize.small:
        return ResponsiveConfig.md;
      case ButtonSize.medium:
        return ResponsiveConfig.lg;
      case ButtonSize.large:
        return ResponsiveConfig.xl;
    }
  }
}

class CanCanStatusBadge extends StatelessWidget {
  final String text;
  final CanCanStatus status;
  final bool showIcon;
  final double? fontSize;

  const CanCanStatusBadge({
    super.key,
    required this.text,
    required this.status,
    this.showIcon = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = fontSize ?? ResponsiveConfig.fontSm;
    final responsivePadding = EdgeInsets.symmetric(
      horizontal: ResponsiveConfig.md,
      vertical: ResponsiveConfig.xs,
    );

    Color backgroundColor;
    Color textColor;
    IconData iconData;

    switch (status) {
      case CanCanStatus.success:
        backgroundColor = AppTheme.successBackground.withOpacity(0.15);
        textColor = AppTheme.primaryGreen;
        iconData = Icons.check_circle_rounded;
        break;
      case CanCanStatus.warning:
        backgroundColor = AppTheme.cautionColor.withOpacity(0.15);
        textColor = AppTheme.cautionColor;
        iconData = Icons.warning_rounded;
        break;
      case CanCanStatus.error:
        backgroundColor = AppTheme.errorRed.withOpacity(0.15);
        textColor = AppTheme.errorRed;
        iconData = Icons.error_rounded;
        break;
      case CanCanStatus.info:
        backgroundColor = AppTheme.infoColor.withOpacity(0.15);
        textColor = AppTheme.infoColor;
        iconData = Icons.info_rounded;
        break;
    }

    return Container(
      padding: responsivePadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ResponsiveConfig.radiusXLarge),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              iconData,
              size: ResponsiveConfig.iconSm,
              color: textColor,
            ),
            SizedBox(width: ResponsiveConfig.xs),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: responsiveFontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

enum CanCanStatus {
  success,
  warning,
  error,
  info,
}

class CanCanTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool enabled;

  const CanCanTextField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixIconTap,
              )
            : null,
      ),
    );
  }
}

class CanCanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;
  final Widget? leading;

  const CanCanAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ?? (automaticallyImplyLeading ? null : const SizedBox()),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CanCanBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CanCanBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveConfig.isMobileSmall
      ? ResponsiveConfig.iconMd
      : ResponsiveConfig.iconLg;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: ResponsiveConfig.fontXs,
          unselectedFontSize: ResponsiveConfig.fontXs,
          iconSize: iconSize,
          selectedLabelStyle: TextStyle(
            fontSize: ResponsiveConfig.fontXs,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: ResponsiveConfig.fontXs,
            fontWeight: FontWeight.w400,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: iconSize),
              activeIcon: Icon(Icons.home_rounded, size: iconSize),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined, size: iconSize),
              activeIcon: Icon(Icons.receipt_long_rounded, size: iconSize),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined, size: iconSize),
              activeIcon: Icon(Icons.account_balance_wallet_rounded, size: iconSize),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined, size: iconSize),
              activeIcon: Icon(Icons.inventory_2_rounded, size: iconSize),
              label: 'Stock',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined, size: iconSize),
              activeIcon: Icon(Icons.person_rounded, size: iconSize),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class CanCanLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;

  const CanCanLoadingIndicator({
    super.key,
    this.message,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class CanCanEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Color? iconColor;

  const CanCanEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionText,
    this.onActionPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveIconSize = ResponsiveConfig.icon2Xl;
    final responsivePadding = EdgeInsets.all(ResponsiveConfig.xl);

    return Center(
      child: Padding(
        padding: responsivePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveConfig.lg),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.textSecondary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: responsiveIconSize,
                color: iconColor ?? AppTheme.textSecondary.withOpacity(0.6),
              ),
            ),
            SizedBox(height: ResponsiveConfig.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveConfig.fontXl,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveConfig.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: ResponsiveConfig.fontMd,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onActionPressed != null) ...[
              SizedBox(height: ResponsiveConfig.xl),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveConfig.isTablet ? 300.w : double.infinity,
                ),
                child: CanCanButton(
                  text: actionText!,
                  onPressed: onActionPressed,
                  icon: Icons.add_rounded,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}