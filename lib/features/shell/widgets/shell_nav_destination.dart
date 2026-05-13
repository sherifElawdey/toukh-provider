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
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                : const EdgeInsets.all(10),
            decoration: selected
                ? BoxDecoration(
                    color: AppColors.bottomNavPill,
                    borderRadius: BorderRadius.circular(28),
                  )
                : null,
            child: selected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(item.selectedIcon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: CustomText(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  )
                : Icon(item.icon, color: unselectedIconColor, size: 26),
          ),
        ),
      ),
    );
  }
}
