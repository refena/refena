import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@internal
class LiveButton extends StatelessWidget {
  final bool live;
  final void Function() onTap;

  const LiveButton({
    required this.live,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor:
            live ? Colors.red : Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: onTap,
      child: Row(
        children: [
          if (live)
            // red dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
          else
            const Icon(Icons.pause),
          const SizedBox(width: 10),
          Text(live ? 'Live' : 'Paused'),
        ],
      ),
    );
  }
}
