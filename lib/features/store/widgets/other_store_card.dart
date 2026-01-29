import 'package:flutter/material.dart';

import '../models/store_models.dart';

class OtherStoreCard extends StatelessWidget {
  const OtherStoreCard({super.key, required this.store, this.onTap});

  final StoreListItem store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    //Material + InkWell로 감싸서 카드 탭 가능하게 처리
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 164,
          height: 189,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFFFFF), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  height: 122,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FFFFFF), Color(0x33FFA588)],
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildStoreImage(),
                    ),
                  ),
                ),
              ),
              Expanded(
                // Expanded를 사용해 남은 공간 차지 + 높이 유지
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF767676),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (store.open == true) ? '영업 중' : '영업 종료',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6E3F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreImage() {
    final url = (store.imageUrl ?? '').trim();
    if (url.isEmpty) {
      return _buildNoImage();
    }
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildNoImage(),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildNoImage(),
    );
  }

  Widget _buildNoImage() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Text(
        'No Img',
        style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}
