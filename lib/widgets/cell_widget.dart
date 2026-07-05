import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/move_model.dart';

class CellWidget extends StatefulWidget {
  final Player? player;
  final int row;
  final int col;
  final VoidCallback onTap;
  final bool isWinningCell;
  final bool isLastMove;

  const CellWidget({
    super.key,
    required this.player,
    required this.row,
    required this.col,
    required this.onTap,
    required this.isWinningCell,
    required this.isLastMove,
  });

  @override
  State<CellWidget> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<CellWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    if (widget.player != null) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant CellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player == null && widget.player != null) {
      _controller.reset();
      _controller.forward();
    } else if (widget.player == null) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isWinningCell
        ? const Color(0xFFF5B700)
        : const Color(0xFFE7E7EF);
    final background = widget.isWinningCell
        ? const Color(0xFFFFE082)
        : widget.isLastMove
        ? const Color(0xFFEAF3FF)
        : const Color(0xFFF7F7FB);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.player == null ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: borderColor,
            width: widget.isWinningCell ? 1.2 : 0.35,
          ),
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.player == null
              ? const SizedBox.shrink()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final shortest = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return Text(
                      widget.player!.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.player!.color,
                        fontSize: shortest * 0.7,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
