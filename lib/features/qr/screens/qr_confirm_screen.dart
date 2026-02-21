import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "'매장이름'에서 명부를 등록하시겠습니까?" 확인 화면
class QrConfirmScreen extends StatelessWidget {
  final String storeName;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const QrConfirmScreen({
    super.key,
    required this.storeName,
    required this.isLoading,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading ? null : onBack,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icon/QR_Active.svg',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 18),
                  children: [
                    const TextSpan(
                      text: "'",
                      style: TextStyle(
                          color: Color(0xFFF97316), fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: storeName,
                      style: const TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: "'",
                      style: TextStyle(
                          color: Color(0xFFF97316), fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '에서 명부를 등록하시겠습니까?'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '명부 등록은 1일 1회만 가능합니다',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
