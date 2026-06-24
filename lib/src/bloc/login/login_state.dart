import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String token;

  const LoginSuccess({required this.token});

  @override
  List<Object?> get props => [token];
}

class LoginFailure extends LoginState {
  final String error;
  final int? statusCode;

  const LoginFailure({required this.error, this.statusCode});

  @override
  List<Object?> get props => [error];
}
