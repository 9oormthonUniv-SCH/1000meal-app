import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

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
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray2, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: Offset.zero,
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.lightOrange.withValues(alpha: 0.2),
                      ],
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
                        style: AppTypography.body3.copyWith(
                          color: AppColors.gray7,
                          fontSize: 14,
                          height: 20 / 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (store.open == true) ? '영업 중' : '영업 종료',
                        style: AppTypography.caption1.copyWith(
                          color: store.open == true ? AppColors.orange : AppColors.gray7,
                          height: 20 / 12,
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
      color: AppColors.background,
      alignment: Alignment.center,
      child: Text(
        'No Img',
        style: AppTypography.caption2.copyWith(
          fontSize: 11,
          color: AppColors.gray7,
        ),
      ),
    );
  }
}
