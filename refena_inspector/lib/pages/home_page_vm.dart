import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/pages/home_page_controller.dart';
import 'package:refena_inspector/service/server_service.dart';

class HomePageVm {
  final PageController pageController;
  final HomeTab currentTab;
  final bool serverRunning;
  final bool clientConnected;
  final void Function(int tab) changeTab;

  const HomePageVm({
    required this.pageController,
    required this.currentTab,
    required this.serverRunning,
    required this.clientConnected,
    required this.changeTab,
  });

  @override
  String toString() {
    return 'HomePageVm(currentTab: $currentTab, serverRunning: $serverRunning, clientConnected: $clientConnected)';
  }
}

final homePageVmProvider = ViewProvider((ref) {
  final state = ref.watch(homePageControllerProvider);
  final serverState = ref.watch(serverProvider);

  return HomePageVm(
    pageController: state.pageController,
    currentTab: state.currentTab,
    serverRunning: serverState.running,
    clientConnected: serverState.clientConnected,
    changeTab: (tab) => ref
        .redux(homePageControllerProvider)
        .dispatch(SetHomeTabAction(HomeTab.values[tab])),
  );
});
