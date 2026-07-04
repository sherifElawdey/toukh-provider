import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/home_service_schedule_helpers.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_cubit.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_schedule_day_tabs.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_schedule_job_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeServiceScheduleTab extends StatefulWidget {
  const HomeServiceScheduleTab({super.key});

  @override
  State<HomeServiceScheduleTab> createState() => _HomeServiceScheduleTabState();
}

class _HomeServiceScheduleTabState extends State<HomeServiceScheduleTab> {
  int _selectedDayIndex = schedulePastDays;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderHomeServiceRequestsCubit,
        ProviderHomeServiceRequestsState>(
      builder: (context, state) {
        if (state.loading && state.requests.isEmpty) {
          return const Center(child: AppLoadingMark());
        }

        final days = state.scheduleDayTabs();
        if (_selectedDayIndex >= days.length) {
          _selectedDayIndex = state.scheduleTodayTabIndex();
        }
        final selectedDay = days[_selectedDayIndex];
        final jobs = state.jobsForDay(selectedDay);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeServiceScheduleDayTabs(
              days: days,
              selectedIndex: _selectedDayIndex,
              centerOnIndex: state.scheduleTodayTabIndex(),
              jobCountForDay: state.jobCountForDay,
              onSelected: (index) => setState(() => _selectedDayIndex = index),
            ),
            Expanded(
              child: jobs.isEmpty
                  ? Center(
                      child: HomeDashboardEmptyPlaceholder(
                        message: AppStrings.HomeServiceSchedule.emptyDay.tr,
                        compact: true,
                      ),
                    )
                  : ListView.separated(
                      padding: AppSizes.screenPadding.copyWith(
                        top: AppSizes.spaceSm,
                        bottom: AppSizes.space2xl,
                      ),
                      itemCount: jobs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSizes.spaceMd),
                      itemBuilder: (context, index) {
                        return HomeServiceScheduleJobCard(
                          request: jobs[index],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
