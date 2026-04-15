import 'package:flutter/material.dart';

class GlobalFooter extends StatelessWidget {
  const GlobalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      color: Colors.black.withOpacity(0.8),
      child: Align(
        alignment: isMobile ? Alignment.center : Alignment.centerLeft,
        child: Text(
          '© 2026 Pelindo Terminal Petikemas Teluk Lamong - TPK Nilam',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          softWrap: true,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 11 : 12,
          ),
        ),
      ),
    );
  }
}
