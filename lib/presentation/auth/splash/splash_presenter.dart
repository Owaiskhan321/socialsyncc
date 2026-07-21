import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';
import '../../../core/network/session_storage.dart';

class SplashState extends Equatable {
  const SplashState({this.ready = false});
  final bool ready;
  @override
  List<Object?> get props => [ready];
}

abstract class SplashView implements MvpView {
  void goToWelcome();
  void goToHome();
}

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(const SplashState());
  void markReady() => emit(const SplashState(ready: true));
}

class SplashPresenter extends MvpPresenter<SplashState, SplashView> {
  SplashPresenter() : super(SplashCubit());

  SplashCubit get _c => cubit as SplashCubit;
  Timer? _timer;

  @override
  void onAttached() {
    AppLogger.i('Splash started');
    _timer = Timer(const Duration(milliseconds: 1800), () async {
      if (!cubit.isClosed) {
        _c.markReady();
        AppLogger.event('splash_ready');
        await _routeAfterSplash();
      }
    });
  }

  Future<void> _routeAfterSplash() async {
    if (await SessionStorage.isLoggedIn()) {
      view?.goToHome();
    } else {
      view?.goToWelcome();
    }
  }

  void continueTap() {
    AppLogger.event('splash_continue');
    _routeAfterSplash();
  }

  @override
  void onDetached() {
    _timer?.cancel();
    _timer = null;
  }
}
