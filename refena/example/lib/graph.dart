import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

void main() {
  runApp(RefenaScope(
    child: _App(),
  ));
}

class _App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _GraphPlaygroundPage(),
    );
  }
}

enum _Mode {
  viewModel,
  controller,
  viewModelAndController,
}

class _GraphPlaygroundPage extends StatefulWidget {
  @override
  State<_GraphPlaygroundPage> createState() => _GraphPlaygroundPageState();
}

class _GraphPlaygroundPageState extends State<_GraphPlaygroundPage> with Refena {
  _Mode _mode = _Mode.viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding:
            const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 50),
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RefenaGraphPage(
                    showWidgets: true,
                  ),
                ),
              ),
              child: const Text('Show graph'),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: DropdownMenu<_Mode>(
              initialSelection: _mode,
              onSelected: (_Mode? value) {
                if (value == null) {
                  return;
                }
                ref.dispose(_viewModelProvider);
                ref.dispose(_controllerProvider);
                ref.dispose(_viewModelControllerProvider);
                setState(() {
                  _mode = value;
                });
              },
              dropdownMenuEntries: _Mode.values
                  .map(
                    (mode) => DropdownMenuEntry<_Mode>(
                      value: mode,
                      label: mode.name,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: switch(_mode) {
              _Mode.viewModel => _ViewModelWidget(),
              _Mode.controller => _ControllerWidget(),
              _Mode.viewModelAndController => _ViewModelControllerWidget(),
            },
          )
        ],
      ),
    );
  }
}

final _viewModelProvider = ViewProvider((ref) => 10, debugLabel: 'ViewModel');

class _ViewModelWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.ref.watch(_viewModelProvider);
    return Text('Single view model');
  }
}

final _controllerProvider = NotifierProvider<_Controller, int>((ref) => _Controller(), debugLabel: 'Controller');

class _Controller extends Notifier<int> {
  @override
  int init() => 10;
}

class _ControllerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.ref.watch(_controllerProvider);
    return Text('Controller');
  }
}

final _viewModelControllerProvider = ViewProvider((ref) {
  return ref.watch(_controllerProvider);
}, debugLabel: 'ViewModelController');

class _ViewModelControllerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.ref.watch(_viewModelControllerProvider);
    return Text('View model and controller');
  }
}

