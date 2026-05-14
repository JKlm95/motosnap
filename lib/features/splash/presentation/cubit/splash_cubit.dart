import 'package:flutter_bloc/flutter_bloc.dart';

import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(const SplashState());

  Future<void> runSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    emit(const SplashState(phase: SplashPhase.done));
  }
}
