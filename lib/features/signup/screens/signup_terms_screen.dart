import 'package:flutter/material.dart';

class SignupTermsScreen extends StatelessWidget {
  static const routeName = '/signup/terms';

  final String doc; // 'tos' | 'privacy'

  const SignupTermsScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final title = doc == 'privacy' ? '개인정보 수집 및 이용 동의' : '이용약관';

    return Scaffold(
      appBar: AppBar(title: const Text('약관')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '여기에 ${doc == 'privacy' ? '개인정보 처리방침' : '이용약관'} 전문을 넣어주세요.\n'
                    '임시 문구입니다. 추후 마크다운/서버 콘텐츠로 교체 가능합니다.',
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF374151)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


