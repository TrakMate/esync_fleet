import 'package:flutter/material.dart';

class HoverWrapper extends StatefulWidget {
  final Widget Function(bool isHovered) builder;

  const HoverWrapper({super.key, required this.builder});

  @override
  _HoverWrapperState createState() => _HoverWrapperState();
}

class _HoverWrapperState extends State<HoverWrapper> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: widget.builder(isHovered),
      ),
    );
  }
}
