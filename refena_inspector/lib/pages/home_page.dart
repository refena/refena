import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/pages/home/actions_page.dart';
import 'package:refena_inspector/pages/home/graph_page.dart';
import 'package:refena_inspector/pages/home/redux_page.dart';
import 'package:refena_inspector/pages/home/settings_page.dart';
import 'package:refena_inspector/pages/home/tracing_page.dart';
import 'package:refena_inspector/pages/home_page_controller.dart';
import 'package:refena_inspector/pages/home_page_vm.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final vm = ref.watch(homePageVmProvider);

    if (!vm.clientConnected) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Waiting for client connection...'),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: vm.currentTab.index,
            onDestinationSelected: vm.changeTab,
            extended: true,
            leading: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/img/inspector-logo-512-white.webp',
                  width: 200,
                ),
                const SizedBox(height: 20),
              ],
            ),
            destinations: HomeTab.values.map((tab) {
              return NavigationRailDestination(
                icon: switch (tab) {
                  HomeTab.tracing => Icon(Icons.list),
                  HomeTab.redux => Icon(Icons.table_chart),
                  HomeTab.graph => Icon(Icons.share),
                  HomeTab.actions => Icon(Icons.bolt),
                  HomeTab.settings => Icon(Icons.settings),
                },
                label: Text(tab.label),
              );
            }).toList(),
          ),
          Expanded(
            child: PageView(
              controller: vm.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                TracingPage(),
                ReduxPage(),
                GraphPage(),
                ActionsPage(),
                SettingsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
