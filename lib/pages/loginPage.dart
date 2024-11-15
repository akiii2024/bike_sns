import 'package:flutter/material.dart';
import 'homePage.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text('テストユーザー1'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // ユーザー2を選択した時の処理
              },
              child: const Text('テストユーザー2'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // ユーザー3を選択した時の処理
              },
              child: const Text('テストユーザー3'),
            ),
          ],
        ),
      ),
    );
  }
}
