import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/domain/repositories/delivery_company_repository.dart';

class CompanyEarningsState extends Equatable {
  const CompanyEarningsState({
    this.loading = true,
    this.failed = false,
    this.earnings,
  });

  final bool loading;
  final bool failed;
  final CompanyEarnings? earnings;

  @override
  List<Object?> get props => [loading, failed, earnings];
}

class CompanyEarningsCubit extends Cubit<CompanyEarningsState> {
  CompanyEarningsCubit(this._repo) : super(const CompanyEarningsState()) {
    load();
  }

  final DeliveryCompanyRepository _repo;

  Future<void> load() async {
    emit(CompanyEarningsState(earnings: state.earnings));
    try {
      final earnings = await _repo.fetchEarnings();
      if (isClosed) return;
      emit(CompanyEarningsState(loading: false, earnings: earnings));
    } catch (e) {
      debugPrint('CompanyEarningsCubit: load failed: $e');
      if (isClosed) return;
      emit(
        CompanyEarningsState(
          loading: false,
          failed: true,
          earnings: state.earnings,
        ),
      );
    }
  }
}
