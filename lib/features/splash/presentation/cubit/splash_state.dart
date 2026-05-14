import 'package:equatable/equatable.dart';

enum SplashPhase { showing, done }

enum SplashDestination { login, shell }

class SplashState extends Equatable {
  const SplashState({this.phase = SplashPhase.showing, this.destination});

  final SplashPhase phase;
  final SplashDestination? destination;

  @override
  List<Object?> get props => [phase, destination];
}
