// --- HoverActionCard WIDGET ---
import 'package:flutter/material.dart';

class HoverActionCard extends StatefulWidget {
  final String assetName;
  final String title;
  final Color titleColor;
  final VoidCallback onTap;
  final Color iconColor;
  final Gradient lightGradient;
  final Gradient darkGradient;

  const HoverActionCard({
    super.key,
    required this.assetName,
    required this.title,
    required this.titleColor,
    required this.onTap,
    required this.iconColor,
    required this.lightGradient,
    required this.darkGradient,
  });

  @override
  State<HoverActionCard> createState() => _HoverActionCardState();
}

class _HoverActionCardState extends State<HoverActionCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _hovering ? widget.darkGradient : widget.lightGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _hovering
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/icons/forum/' + widget.assetName,
                      width: 20,
                      height: 20,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _hovering ? Colors.white : widget.titleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- END HoverActionCard ---
