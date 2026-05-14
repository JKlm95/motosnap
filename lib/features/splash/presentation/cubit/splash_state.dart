import 'package:equatable/equatable.dart';

enum SplashPhase { showing, done }

class SplashState extends Equatable {
  const SplashState({this.phase = SplashPhase.showing});

  final SplashPhase phase;

  @override
  List<Object?> get props => [phase];
}
