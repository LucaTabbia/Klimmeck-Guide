import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/utils/app_log.dart';

import '../../../repository/cache/cache_expiry.dart';
import '../../../repository/cache/image_warmer.dart';
import '../../../repository/services/graphql/graphql.dart';
import '../../../repository/storage/storage_manager.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> with SafeEmit<SplashState> {
  SplashCubit(this.rest, {KlimmeckGraphQl? graphQl, ImageWarmer? warmer})
    : _graphQl = graphQl,
      _warmer = warmer ?? ImageWarmer(),
      super(const SplashInitial());

  /// Dopo questo intervallo senza esito il cold start mostra l'hint di rete (D-18).
  static const Duration connectionHintDelay = Duration(seconds: 10);

  final KlimmeckRest rest;

  /// Senza client GraphQL il cold start riscalda la sola cartella `main`.
  final KlimmeckGraphQl? _graphQl;
  final ImageWarmer _warmer;
  Timer? _bootstrapWatch;

  void startBootstrapWatch() {
    if (_bootstrapWatch != null) return;
    _bootstrapWatch = Timer(connectionHintDelay, () {
      emit(const SplashNetworkDelayed());
    });
  }

  void stopBootstrapWatch() {
    _bootstrapWatch?.cancel();
    _bootstrapWatch = null;
    if (state is SplashNetworkDelayed) emit(const SplashInitial());
  }

  /// Riscalda la cartella Cloudinary [folder] e poi le immagini delle lore del
  /// personaggio (Phase 17 D-22): il primo avvio paga i download una volta, i
  /// successivi leggono il disco. La shell parte sia con [SplashData] sia con
  /// [SplashError]; il passo delle lore non blocca mai il boot.
  Future<void> getImages(String folder) async {
    try {
      final imageUrls = await _folderImageUrls(folder);
      if (imageUrls == null || imageUrls.isEmpty) {
        emit(const SplashError("No images"));
        return;
      }
      await _warmer.warm(imageUrls);
      await _warmLoreImages();
      emit(const SplashData());
    } catch (e) {
      appLog('[Splash] image preload failed: ${e.runtimeType}');
      emit(SplashError(e.toString()));
    }
  }

  Future<List<String>?> _folderImageUrls(String folder) async {
    if (await CacheExpiry.isCacheValid()) {
      return KGStorageManager.getCachedUrls();
    }
    final imageUrls = await rest.fetchCloudinarySubfoldersUrls(folder);
    await KGStorageManager.saveCachedUrls(imageUrls);
    await CacheExpiry.setExpiry();
    return imageUrls;
  }

  Future<void> _warmLoreImages() async {
    final graphQl = _graphQl;
    if (graphQl == null) return;
    try {
      final lores = await graphQl.getAllLores();
      await _warmer.warm(lores.map((lore) => lore.image).whereType<String>());
    } catch (e) {
      appLog('[Splash] lore warm-up skipped: ${e.runtimeType}');
    }
  }

  @override
  Future<void> close() {
    _bootstrapWatch?.cancel();
    _bootstrapWatch = null;
    return super.close();
  }
}
