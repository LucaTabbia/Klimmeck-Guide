import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';

import '../../../repository/cache/cache_expiry.dart';
import '../../../repository/cache/svg_cache.dart';
import '../../../repository/cache/svg_cache_manager.dart';
import '../../../repository/storage/storage_manager.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this.rest) : super(const SplashInitial());

  /// Dopo questo intervallo senza esito il cold start mostra l'hint di rete (D-18).
  static const Duration connectionHintDelay = Duration(seconds: 10);

  late final svgCacheManager = SvgCacheManager();
  final KlimmeckRest rest;
  Timer? _bootstrapWatch;

  void startBootstrapWatch() {
    if (_bootstrapWatch != null) return;
    _bootstrapWatch = Timer(connectionHintDelay, () {
      if (!isClosed) emit(const SplashNetworkDelayed());
    });
  }

  void stopBootstrapWatch() {
    _bootstrapWatch?.cancel();
    _bootstrapWatch = null;
    if (state is SplashNetworkDelayed) emit(const SplashInitial());
  }

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
        final files = await Future.wait(
          imageUrls.map((url) => svgCacheManager.getSingleFile(url)),
        );
        for (int i = 0; i < imageUrls.length; i++) {
          SvgCache().add(imageUrls[i], files[i]);
        }
        emit(const SplashData());
      } else {
        emit(const SplashError("No images"));
      }
    } catch (e) {
      debugPrint('[Splash] image preload failed: ${e.runtimeType}');
      emit(SplashError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _bootstrapWatch?.cancel();
    _bootstrapWatch = null;
    return super.close();
  }
}
