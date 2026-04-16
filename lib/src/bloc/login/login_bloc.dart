import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../services/apiURL.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final response = await http.post(
        Uri.parse(BaseURLConfig.loginApiURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': event.username,
          'password': event.password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Expecting API to return {"accessToken": "..."}
        final token = data['accessToken'] ?? data['token'];
        if (token != null && token.isNotEmpty) {
          emit(LoginSuccess(token: token));
        } else {
          emit(const LoginFailure(error: 'Invalid response: missing token'));
        }
      } else {
        final errorData = jsonDecode(response.body);
        emit(
          LoginFailure(
            error:
                errorData['error'] ?? 'Login failed (${response.statusCode})',
          ),
        );
      }
    } catch (error) {
      emit(LoginFailure(error: error.toString()));
    }
  }
}
