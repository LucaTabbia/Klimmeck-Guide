import 'package:bloc/bloc.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:meta/meta.dart';

import '../../../repository/cache/cache_expiry.dart';
import '../../../repository/cache/svg_cache.dart';
import '../../../repository/cache/svg_cache_manager.dart';
import '../../../repository/storage/storage_manager.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this.rest) : super(SplashInitial());

  final svgCacheManager = SvgCacheManager();
  final KlimmeckRest rest;

  Future<void> getImages(String folder) async {
    try {
      List<String>? imageUrls;
      final valid = await CacheExpiry.isCacheValid();
      if (!valid) {
        imageUrls = await rest.fetchCloudinarySubfoldersUrls(folder);
        await KGStorageManager.saveCachedUrls(imageUrls);
        await CacheExpiry.setExpiry();
      } else {
        imageUrls = await KGStorageManager.getCachedUrls();
      }
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final files = await Future.wait(imageUrls.map((url) => svgCacheManager.getSingleFile(url)));
        for (int i = 0; i < imageUrls.length; i++) {
          SvgCache().add(imageUrls[i], files[i]);
        }
        emit(SplashData());
      } else {
        emit(SplashError("No images"));
      }
    } catch (e) {
      print(e.toString());
      emit(SplashError(e.toString()));
    }
  }
}
