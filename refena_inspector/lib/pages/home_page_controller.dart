import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum HomeTab {
  tracing(Icons.manage_search),
  graph(Icons.account_tree),
  actions(Icons.bolt);

  const HomeTab(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case HomeTab.tracing:
        return 'Tracing';
      case HomeTab.graph:
        return 'Graph';
      case HomeTab.actions:
        return 'Actions';
    }
  }
}

class HomePageState {
  final PageController pageController;
  final HomeTab currentTab;

  const HomePageState({
    required this.pageController,
    required this.currentTab,
  });

  HomePageState copyWith({
    HomeTab? currentTab,
  }) {
    return HomePageState(
      pageController: pageController,
      currentTab: currentTab ?? this.currentTab,
    );
  }

  @override
  String toString() {
    return 'HomePageState(currentTab: $currentTab)';
  }
}

final homePageControllerProvider =
    ReduxProvider<HomePageController, HomePageState>(
  (ref) => HomePageController(),
);

class HomePageController extends ReduxNotifier<HomePageState> {
  @override
  HomePageState init() {
    return HomePageState(
      pageController: PageController(initialPage: HomeTab.tracing.index),
      currentTab: HomeTab.tracing,
    );
  }

  @override
  void dispose() {
    state.pageController.dispose();
    super.dispose();
  }
}

class SetHomeTabAction extends ReduxAction<HomePageController, HomePageState> {
  final HomeTab tab;

  SetHomeTabAction(this.tab);

  @override
  HomePageState reduce() {
    state.pageController.jumpToPage(tab.index);
    return state.copyWith(
      currentTab: tab,
    );
  }
}
