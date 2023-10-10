import 'dart:developer';
import 'package:dart_either/dart_either.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/datasource/local/preferences.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/datasource/remote/auth/auth_api.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/datasource/remote/base_api.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/datasource/remote/data_state.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/models/app_error.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/models/token/sign_in_response.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/models/token/token_model.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/entities/user/user.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/repositories/auth_repositories.dart';
import 'package:flutter_base_clean_architecture/core/components/network/app_exception.dart';
import 'package:flutter_base_clean_architecture/core/components/utils/validators.dart';
import 'package:injectable/injectable.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

void delayed() async {
  await Future.delayed(const Duration(seconds: 6));
}

@Injectable(as: AuthRepository)
class AuthRepositoryImpl extends BaseApi implements AuthRepository {
  final AuthApi _authApi;

  AuthRepositoryImpl(this._authApi);

  @override
  SingleResult<TokenModel?> login(
      {required String email, required String password}) {
    return SingleResult.fromCallable(
      () async {
        final body = {'email': email, 'password': password};
        final response = await getStateOf<SignInResponse?>(
          request: () async => await _authApi.login(body: body),
        );
        if (response is DataFailed) {
          return Either.left(
            AppException(message: response.dioError?.message ?? 'Error'),
          );
        }
        if (response.data == null) {
          return Either.left(AppException(message: 'Data error'));
        }
        final tokenModel = response.data!.token;
        if (Validator.tokenNull(tokenModel)) {
          return Either.left(AppException(message: 'Data null'));
        }

        ///[Print] log data
        log("[Access] ${tokenModel.access?.token}");
        log("[Refresh] ${tokenModel.refresh?.token}");
        log("[Expired time] ${DateFormat().add_yMd().format(tokenModel.access?.expires ?? DateTime.now())}");

        await CommonAppSettingPref.setExpiredTime(
            (tokenModel.access?.expires ?? DateTime.now())
                .millisecondsSinceEpoch);
        await CommonAppSettingPref.setAccessToken(
            tokenModel.access?.token ?? '');
        await CommonAppSettingPref.setRefreshToken(
            tokenModel.refresh?.token ?? '');

        return Either.right(tokenModel);
      },
    );
  }

  @override
  SingleResult<User?> register(
      {required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  SingleResult<bool?> resetPassword({required String email}) =>
      SingleResult.fromCallable(() async {
        final response = await getStateOf(
          request: () async => _authApi.resetPassword(body: {"email": email}),
        );
        return response.toBoolResult();
      });

  @override
  SingleResult<bool?> facebookSignIn() {
    // TODO: implement facebookSignIN
    throw UnimplementedError();
  }

  @override
  SingleResult<bool?> googleSignIn() => SingleResult.fromCallable(() async {
        GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'https://www.googleapis.com/auth/userinfo.profile',
          ],
        );
        try {
          final googleSignInAccount = await googleSignIn.signIn();
          if (googleSignInAccount == null) {
            return Either.left(AppException(message: "Google sign in error"));
          }
          String? accessToken = "";
          await googleSignInAccount.authentication.then((value) {
            accessToken = value.accessToken;
          });
          if (accessToken?.isNotEmpty ?? false) {
            final response = await getStateOf(
              request: () async =>
                  _authApi.googleSignIn(body: {"access_token": accessToken}),
            );
            return response.toBoolResult();
          }
          return Either.left(AppException(message: "Google sign in error"));
        } catch (e) {
          return Either.left(AppException(message: e.toString()));
        }
      });

  @override
  SingleResult<bool?> verifyAccountEmail({required String token}) =>
      SingleResult.fromCallable(
        () async {
          final response = await getStateOf(
            request: () async => _authApi.verifyEmailAccount(token),
          );
          return response.toBoolResult();
        },
      );
}
