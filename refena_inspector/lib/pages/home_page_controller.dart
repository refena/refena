import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum HomeTab {
  tracing,
  redux,
  graph,
  actions,
  settings;

  String get label {
    return switch (this) {
      HomeTab.tracing => 'Tracing',
      HomeTab.redux => 'Redux',
      HomeTab.graph => 'Graph',
      HomeTab.actions => 'Actions',
      HomeTab.settings => 'Settings',
    };
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

/// Refreshes the page controller with the current tab.
class RefreshPageController
    extends ReduxAction<HomePageController, HomePageState> {
  @override
  HomePageState reduce() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.pageController.hasClients) {
        return;
      }
      state.pageController.jumpToPage(state.currentTab.index);
    });
    return state;
  }
}
