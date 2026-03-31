import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:monitoring/utils/auth_helper.dart';

/// Shared frosted-glass panel used across dark pages (alerts, report, etc.).
BoxDecoration appGlassDecoration({
  double borderRadius = 20,
  double fillOpacity = 0.10,
  double borderOpacity = 0.28,
}) {
  return BoxDecoration(
    color: Colors.white.withOpacity(fillOpacity),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: Colors.white.withOpacity(borderOpacity),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.22),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Widget liquidGlassCard({
  required Widget child,
  double borderRadius = 20,
  EdgeInsetsGeometry? padding,
  double blurSigma = 14,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Container(
        padding: padding,
        decoration: appGlassDecoration(borderRadius: borderRadius),
        child: child,
      ),
    ),
  );
}

/// Inline glass field for date triggers / compact dropdown rows on dark UIs.
BoxDecoration appGlassFieldDecoration({double radius = 16}) {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.08),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withOpacity(0.22)),
  );
}

// Responsive helper functions
bool isMobileScreen(BuildContext context) {
  return MediaQuery.of(context).size.width < 600;
}

bool isTabletScreen(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= 600 && width <= 1024;
}

bool isDesktopScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 1024;
}

double getResponsivePadding(BuildContext context) {
  if (isMobileScreen(context)) return 8.0;
  if (isTabletScreen(context)) return 14.0;
  return 20.0;
}

double getResponsiveFontSize(
    BuildContext context, double mobileSize, double desktopSize) {
  if (isMobileScreen(context)) return mobileSize;
  if (isTabletScreen(context)) return (mobileSize + desktopSize) / 2;
  return desktopSize;
}

int getResponsiveGridColumns(BuildContext context,
    {int mobileColumns = 1, int desktopColumns = 3}) {
  if (isMobileScreen(context)) return mobileColumns;
  if (isTabletScreen(context)) {
    final tabletColumns = ((mobileColumns + desktopColumns) / 2).round();
    return tabletColumns < 1 ? 1 : tabletColumns;
  }
  return desktopColumns;
}

double getResponsiveChildAspectRatio(BuildContext context,
    {double mobileRatio = 0.9, double desktopRatio = 1.2}) {
  final isMobile = isMobileScreen(context);
  return isMobile ? mobileRatio : desktopRatio;
}

// Helper function untuk navigasi dengan loading animation
Future<void> navigateWithLoading(BuildContext context, String routeName) async {
  final rootNav = Navigator.of(context, rootNavigator: true);
  showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (context) => WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
          ),
        ),
      ),
    ),
  );

  await Future.delayed(const Duration(milliseconds: 500));

  try {
    if (rootNav.canPop()) {
      rootNav.pop();
    }
    rootNav.pushReplacementNamed(routeName);
  } catch (e) {
    if (rootNav.canPop()) {
      rootNav.pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed Navigation: $routeName'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Global logout dialog function with AuthHelper
void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout', style: TextStyle(color: Colors.black87)),
      content: const Text('Are You Sure To Logout?',
          style: TextStyle(color: Colors.black87)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
        ),
        ElevatedButton(
          onPressed: () async {
            // Clear user data using AuthHelper
            await AuthHelper.clearUserData();

            if (context.mounted) {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

// Helper function untuk membuat liquid glass button dengan hover effect
Widget buildLiquidGlassButton(String text, VoidCallback onPressed,
    {bool isActive = false}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(25),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.2),
              hoverColor: Colors.white.withOpacity(0.15),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Show alert dialog with fade animation
void showFadeAlertDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
  bool barrierDismissible = true,
  ShapeBorder? shape,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
        shape: shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
