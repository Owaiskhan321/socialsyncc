import 'package:flutter_bloc/flutter_bloc.dart';

import '../logger/app_logger.dart';

/// Base MVP contract — View side.
abstract class MvpView {
  void showMessage(String message);
}

/// Base Presenter that owns a Cubit for reactive state (MVP + BLoC).
abstract class MvpPresenter<S, V extends MvpView> {
  MvpPresenter(this.cubit);

  final Cubit<S> cubit;
  V? _view;

  V? get view => _view;
  S get state => cubit.state;

  void attach(V view) {
    _view = view;
    AppLogger.d('$runtimeType attached');
    onAttached();
  }

  void detach() {
    AppLogger.d('$runtimeType detached');
    onDetached();
    _view = null;
  }

  void onAttached() {}
  void onDetached() {}

  void dispose() {
    detach();
    cubit.close();
  }
}
