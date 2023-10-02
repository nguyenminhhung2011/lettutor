import 'package:dart_either/dart_either.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/datasource/remote/base_api.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/datasource/remote/data_state.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/datasource/remote/schedule/schedule_api.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/models/app_error.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/entities/boo_info/boo_info.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/entities/pagination/pagination.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/domain/repositories/boo_repositories.dart';
import 'package:flutter_base_clean_architecture/core/components/network/app_exception.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: BooRepositories)
class BooRepositoriesImpl extends BaseApi implements BooRepositories {
  final ScheduleApi _scheduleApi;
  BooRepositoriesImpl(this._scheduleApi);

  @override
  SingleResult<Pagination<BooInfo>> getBooInfo({
    required int page,
    required int perPage,
    required DateTime dateTimeLte,
    String orderBy = 'meeting',
    String sortBy = 'desc',
  }) =>
      SingleResult.fromCallable(() async {
        final queries = <String, dynamic>{
          'page': page,
          'perPage': perPage,
          'dateTimeLte': dateTimeLte.millisecondsSinceEpoch,
          'orderBy': orderBy,
          'sortBy': sortBy,
        };
        final response = await getStateOf(
            request: () async => await _scheduleApi.getBooHistory(queries));
        if (response is DataFailed) {
          return Either.left(
            AppException(message: response.dioError?.message ?? 'Error'),
          );
        }
        final responseData = response.data;
        if (responseData == null) {
          return Either.left(AppException(message: "Data null"));
        }
        return Either.right(
          Pagination<BooInfo>(
            count: responseData.count,
            perPage: perPage,
            currentPage: page,
            rows: responseData.boos.map((e) => e.toEntity()).toList(),
          ),
        );
      });
}
