import 'package:flutter/material.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 72,
    contentPadding: EdgeInsets.zero,
    title: title,
    subtitle: subtitle,
    leading: leading,
    trailing: trailing,
    onTap: onTap,
  );
}
