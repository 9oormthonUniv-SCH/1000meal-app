import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../store/models/store_models.dart';
import '../../store/viewmodels/store_list_view_model.dart';

class FavoriteButton extends StatelessWidget {
  final StoreListItem store;
  const FavoriteButton({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StoreListViewModel>(context, listen: false);
    final isFavorite = store.isFavorite ?? false;
    return IconButton(
      onPressed: () => vm.toggleFavorite(store),
      icon: SvgPicture.asset(
        isFavorite
            ? 'assets/icon/favorite_star_on.svg'
            : 'assets/icon/favorite_star_off.svg',
        width: 24,
        height: 24,
      ),
      highlightColor: Colors.orange.withOpacity(0.2),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
    );
  }
}
