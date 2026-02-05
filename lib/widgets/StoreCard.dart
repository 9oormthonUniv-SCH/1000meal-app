import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';

import '../features/store/models/store_models.dart';

class StoreCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final groups = [...store.menuGroups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final isMultiGroup = groups.length >= 2;

    return GestureDetector(
      onTap: () {
        onTap?.call();
        // 네비게이션 로직 추가 필요
        // Navigator.push(context, ); -> 각 가게 상세페이지로 이동... 라우팅 ㄱㄱ
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // mb-4
        padding: const EdgeInsets.all(12), // p-4
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                menusText,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: stock == 0 ? Colors.red : AppColors.primary,
                ),
              ),
              Text(
                "남았어요!",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                            color: Color(0xFFD1D5DB),
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
                                  color: Color(0xFF9CA3AF),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: g.stock == 0 ? Colors.red : AppColors.primary,
                        ),
                      ),
                      Text(
                        "남았어요!",
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
    color: Colors.grey[200],
    alignment: Alignment.center,
    child: Text(
      "No Img",
      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0x33FFA588), // rgba(255,165,136,0.2)
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
