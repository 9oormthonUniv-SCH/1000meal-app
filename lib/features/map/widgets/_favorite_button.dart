import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/app_snackbar.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../store/models/store_models.dart';
import '../../store/viewmodels/store_list_view_model.dart';

class FavoriteButton extends StatelessWidget {
  final StoreListItem store;
  const FavoriteButton({Key? key, required this.store}) : super(key: key);

  Future<void> _onPressed(BuildContext context) async {
    final token = await context.read<AuthRepository>().getAccessToken();
    if (token == null || token.isEmpty) {
      if (context.mounted) {
        AppSnackBar.show(context, '로그인이 필요한 기능이에요', centered: true);
      }
      return;
    }
    if (!context.mounted) return;
    await context.read<StoreListViewModel>().toggleFavorite(store);
    if (!context.mounted) return;
    final vm = context.read<StoreListViewModel>();
    if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty) {
      AppSnackBar.show(context, vm.errorMessage!, centered: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StoreListViewModel>(context, listen: false);
    final isFavorite = store.isFavorite;
    return IconButton(
      onPressed: () => _onPressed(context),
      icon: SvgPicture.asset(
        isFavorite
            ? 'assets/icon/favorite_star_on.svg'
            : 'assets/icon/favorite_star_off.svg',
        width: 24,
        height: 24,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
    );
  }
}
