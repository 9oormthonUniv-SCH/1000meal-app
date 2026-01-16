import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$title (임시 화면)', style: const TextStyle(fontSize: 16)),
            if (title == '/ (메인)') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/mypage'),
                child: const Text('마이페이지로 이동(임시)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


