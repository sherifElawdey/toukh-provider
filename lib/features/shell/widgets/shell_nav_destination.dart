import 'package:flutter/material.dart';
import 'package:toukh_provider/features/shell/widgets/shell_nav_item.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ShellNavDestination extends StatelessWidget {
  const ShellNavDestination({
    super.key,
    required this.item,
    required this.selected,
    required this.unselectedIconColor,
    required this.onTap,
  });

  final ShellNavItem item;
  final bool selected;
  final Color unselectedIconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pill = dark ? AppColors.appColor : AppColors.bottomNavPill;
    final onPill = dark ? AppColors.onSurface : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: selected
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 11)
                : const EdgeInsets.all(10),
            decoration: selected
                ? BoxDecoration(
                    color: pill,
                    borderRadius: BorderRadius.circular(28),
                  )
                : null,
            child: selected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(item.selectedIcon, color: onPill, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: CustomText(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: onPill,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  )
                : Icon(item.icon, color: unselectedIconColor, size: 24),
          ),
        ),
      ),
    );
  }
}
