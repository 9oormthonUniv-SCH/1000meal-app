import 'package:flutter/material.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';

/// 이용약관·개인정보 수집 및 이용 동의 전문 (내용 보기용)
class SignupTermsScreen extends StatelessWidget {
  static const routeName = '/signup/terms';

  final String doc; // 'tos' | 'privacy'

  const SignupTermsScreen({super.key, required this.doc});

  static const String _termsOfService = '''
제1조 (목적)
본 약관은 오늘순밥(이하 "서비스")이 제공하는 천원의 아침밥 관련 서비스 이용과 관련하여 회사와 이용자 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
① "서비스"란 회사가 제공하는 천원의 아침밥 예약·조회·QR 이용 등 관련 모든 서비스를 의미합니다.
② "이용자"란 본 약관에 따라 서비스를 이용하는 회원 및 비회원을 말합니다.
③ "회원"이란 서비스에 가입하여 이용자 아이디를 부여받은 자를 말합니다.

제3조 (약관의 효력 및 변경)
① 본 약관은 서비스 화면에 게시하거나 기타의 방법으로 공지함으로써 효력이 발생합니다.
② 회사는 필요한 경우 관련 법령을 위반하지 않는 범위에서 본 약관을 변경할 수 있으며, 변경된 약관은 제1항과 같은 방법으로 공지합니다.
③ 이용자가 변경된 약관에 동의하지 않는 경우 서비스 이용을 중단하고 탈퇴할 수 있습니다.

제4조 (서비스의 제공)
회사는 다음과 같은 서비스를 제공합니다.
- 천원의 아침밥 매장 정보 조회
- QR 코드를 통한 식사 이용·등록
- 공지사항 및 운영 안내

제5조 (서비스 이용)
이용자는 서비스를 이용함에 있어 관련 법령 및 본 약관을 준수하여야 하며, 회사의 동의 없이 서비스를 영리 목적으로 이용할 수 없습니다.

제6조 (개인정보의 보호)
회사는 이용자의 개인정보를 「개인정보 수집 및 이용 동의」에 따라 수집·이용·관리하며, 관련 법령을 준수합니다.
''';

  static const String _privacyPolicy = '''
제1조 (개인정보의 수집·이용 목적)
회사는 앱 내 서비스 제공, 학생 인증, QR 이용 및 공지 업로드 등을 위해 개인정보를 수집·이용합니다.

제2조 (수집하는 개인정보 항목)
① 앱 가입·이용 시 수집하는 항목: 학번(아이디), 학교 이메일 주소(@sch.ac.kr), 이름
  - 위 항목은 앱 내 기능 제공 및 학생 본인 인증 목적으로 수집·이용됩니다.
② QR 기능 이용 시: 카메라 접근 권한이 필요하며, QR 코드 스캔을 위한 목적으로만 사용됩니다.
③ 관리자 공지사항 업로드 시(선택): 사진 라이브러리 접근 및 카메라 촬영 권한을 선택적으로 동의하실 수 있으며, 공지 이미지 첨부 시에만 사용됩니다.

제3조 (개인정보의 보유·이용 기간)
이용자의 개인정보는 수집·이용 목적이 달성된 후에는 지체 없이 파기합니다. 단, 관련 법령에 따라 보존할 필요가 있는 경우 해당 기간 동안 보관합니다.

제4조 (개인정보의 제3자 제공)
회사는 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다. 다만, 법령에 의해 요구되는 경우 등 예외적으로 제공할 수 있습니다.

제5조 (이용자의 권리)
이용자는 언제든지 자신의 개인정보를 조회하거나 수정·삭제·처리정지를 요청할 수 있으며, 회사는 이에 대해 지체 없이 조치합니다.

제6조 (개인정보의 안전성 확보)
회사는 개인정보의 안전한 처리를 위해 기술적·관리적 보호조치를 취하고 있습니다.
''';

  @override
  Widget build(BuildContext context) {
    final title = doc == 'privacy' ? '개인정보 수집 및 이용 동의' : '이용약관';
    final content = doc == 'privacy' ? _privacyPolicy : _termsOfService;

    return Scaffold(
      appBar: AppBarCommon(title: title),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTypography.headline4.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content.trim(),
                    style: AppTypography.body4.copyWith(
                      height: 1.6,
                      color: AppColors.black,
                    ),
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


