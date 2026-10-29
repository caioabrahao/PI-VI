import 'package:flutter/material.dart';

const Color cosBackground = Color(0xFF080B0F);
const Color cosPanel = Color(0xFF10151B);
const Color cosPanelElevated = Color(0xFF171E26);
const Color cosBorder = Color(0xFF293640);
const Color cosMuted = Color(0xFF8A98A5);
const Color cosForeground = Color(0xFFF1F5F8);
const Color cosMint = Color(0xFF4FE0C0);

class CosAppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const CosAppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cosMint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cosMint.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.home_rounded, color: cosMint, size: 25),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'COS',
                    style: TextStyle(
                      color: cosForeground,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: cosForeground,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: cosMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class CosAppNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CosAppNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _destinations = [
    (Icons.home_outlined, 'Início'),
    (Icons.memory_outlined, 'Dispositivos'),
    (Icons.account_tree_outlined, 'Automações'),
    (Icons.notifications_none_rounded, 'Alertas'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: cosPanel,
        border: Border(top: BorderSide(color: cosBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (var index = 0; index < _destinations.length; index++)
                Expanded(
                  child: _NavigationItem(
                    icon: _destinations[index].$1,
                    label: _destinations[index].$2,
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: selected
              ? cosMint.withValues(alpha: 0.13)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? cosMint : cosMuted, size: 19),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? cosMint : cosMuted,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
