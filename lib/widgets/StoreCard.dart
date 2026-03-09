import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../features/store/models/store_models.dart';

class StoreCard extends StatefulWidget {
  final StoreListItem store;
  final bool isSelected;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.store,
    this.isSelected = false, // 기본값 false
    this.onTap,
  });

  @override
  State<StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final groups = [...store.menuGroups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final isMultiGroup = groups.length >= 2;
    final showActive = widget.isSelected || _pressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => widget.onTap?.call(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // mb-4
        padding: const EdgeInsets.all(12), // p-4
        decoration: BoxDecoration(
          color: showActive ? AppColors.orangeSelected : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: showActive ? AppColors.lightOrange : AppColors.gray3,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
              offset: Offset.zero,
            ),
          ],
        ),
        child: !isMultiGroup
            ? _SingleGroupLayout(store: store)
            : _MultiGroupLayout(store: store, groups: groups),
      ),
    );
  }
}

class _SingleGroupLayout extends StatelessWidget {
  const _SingleGroupLayout({required this.store});

  final StoreListItem store;

  static const double _imageSize = 48;

  @override
  Widget build(BuildContext context) {
    final menusText = store.singleGroupMenusText;
    final stock = store.firstGroupStock;

    return Row(
      children: [
        _StoreImageBox(imageUrl: store.imageUrl, size: _imageSize),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.name,
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.black,
                  fontSize: 16,
                  height: 32 / 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                menusText,
                style: AppTypography.body3.copyWith(color: AppColors.gray7),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$stock개",
                style: AppTypography.body3.copyWith(
                  color: stock == 0 ? AppColors.error : AppColors.orange,
                  fontSize: 14,
                ),
              ),
              Text(
                "남았어요!",
                style: AppTypography.caption2.copyWith(color: AppColors.gray7),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiGroupLayout extends StatelessWidget {
  const _MultiGroupLayout({required this.store, required this.groups});

  final StoreListItem store;
  final List<TodayMenuGroup> groups;

  static const double _rowHeight = 56;
  static const double _imageSize = 48;
  static const double _dotSize = 6;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _imageSize,
          child: Column(
            children: [
              _StoreImageBox(imageUrl: store.imageUrl, size: _imageSize),
              const SizedBox(height: 2),
              SizedBox(
                height: _rowHeight * groups.length,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 0,
                      // 마지막 점의 중앙까지 이어지도록 bottom 을 rowHeight/2 로 둔다.
                      bottom: _rowHeight / 2,
                      child: SizedBox(
                        width: 2,
                        child: CustomPaint(
                          painter: _VerticalDashedLinePainter(
                            color: AppColors.gray3,
                            dashHeight: 6,
                            dashGap: 4,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        for (int i = 0; i < groups.length; i++)
                          SizedBox(
                            height: _rowHeight,
                            child: Center(
                              child: Container(
                                width: _dotSize,
                                height: _dotSize,
                                decoration: const BoxDecoration(
                                  color: AppColors.gray4,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    store.name,
                    style: AppTypography.subtitle1.copyWith(
                      color: AppColors.black,
                      fontSize: 16,
                      height: 32 / 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              for (final g in groups)
                SizedBox(
                  height: _rowHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      g.menus.isNotEmpty ? g.menus.map((e) => e.name).join(', ') : '메뉴 정보 없음',
                      style: AppTypography.body3.copyWith(color: AppColors.gray7),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 64,
          child: Column(
            children: [
              const SizedBox(height: 50),
              for (final g in groups)
                SizedBox(
                  height: _rowHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "${g.stock}개",
                        style: AppTypography.body3.copyWith(
                          color: g.stock == 0 ? AppColors.error : AppColors.orange,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "남았어요!",
                        style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _buildNoImage() {
  return Container(
    color: AppColors.gray2,
    alignment: Alignment.center,
    child: Text(
      "No Img",
      style: AppTypography.caption2.copyWith(
        fontSize: 10,
        color: AppColors.gray7,
      ),
    ),
  );
}

Widget _buildStoreImage(String urlOrAsset) {
  final value = urlOrAsset.trim();
  final isNetwork = value.startsWith('http://') || value.startsWith('https://');
  if (isNetwork) {
    return Image.network(
      value,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildNoImage(),
    );
  }

  return Image.asset(
    value,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => _buildNoImage(),
  );
}

class _StoreImageBox extends StatelessWidget {
  const _StoreImageBox({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12), // rounded-xl
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.white,
              AppColors.lightOrange.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: url.isNotEmpty ? _buildStoreImage(url) : _buildNoImage(),
      ),
    );
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  _VerticalDashedLinePainter({
    required this.color,
    required this.dashHeight,
    required this.dashGap,
  });

  final Color color;
  final double dashHeight;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..style = PaintingStyle.stroke;

    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      final y2 = (y + dashHeight).clamp(0, size.height).toDouble();
      canvas.drawLine(Offset(x, y), Offset(x, y2), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashHeight != dashHeight ||
        oldDelegate.dashGap != dashGap;
  }
}
