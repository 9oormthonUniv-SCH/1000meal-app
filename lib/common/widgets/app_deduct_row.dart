import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

/// 재고 관리: 10개 / 5개 / 1개 좌측 마이너스 버튼 행
class AppDeductRow extends StatelessWidget {
  const AppDeductRow({
    super.key,
    required this.labels,
    required this.enabledList,
    required this.onDeduct,
    this.labelColor,
  });

  /// 예: ['10개', '5개', '1개']
  final List<String> labels;
  /// 각 셀 활성화 여부 (재고 수량에 따라)
  final List<bool> enabledList;
  /// 인덱스별 차감 콜백
  final ValueChanged<int> onDeduct;
  /// '10개' 등 라벨 텍스트 색상 (미지정 시 비활성 회색)
  final Color? labelColor;

  static const Color _defaultLabelColor = AppColors.gray5;

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? _defaultLabelColor;
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.15), blurRadius: 20, offset: Offset.zero),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _DeductCell(
                label: labels[i],
                labelColor: color,
                enabled: i < enabledList.length ? enabledList[i] : false,
                roundedLeft: i == 0,
                roundedRight: i == labels.length - 1,
                onTap: () => onDeduct(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeductCell extends StatelessWidget {
  const _DeductCell({
    required this.label,
    required this.labelColor,
    required this.enabled,
    required this.onTap,
    this.roundedLeft = false,
    this.roundedRight = false,
  });

  final String label;
  final Color labelColor;
  final bool enabled;
  final VoidCallback onTap;
  final bool roundedLeft;
  final bool roundedRight;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: roundedLeft ? const Radius.circular(16) : Radius.zero,
      bottomLeft: roundedLeft ? const Radius.circular(16) : Radius.zero,
      topRight: roundedRight ? const Radius.circular(16) : Radius.zero,
      bottomRight: roundedRight ? const Radius.circular(16) : Radius.zero,
    );

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: const Border(
            right: BorderSide(color: AppColors.gray5, width: 0.5),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.gray5.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text('–', style: AppTypography.body3.copyWith(color: AppColors.white, height: 1.0)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                  fontFamily: AppTypography.fontFamily,
                  height: 1.0,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
