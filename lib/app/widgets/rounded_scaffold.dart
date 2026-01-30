import 'package:clipshare/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoundedScaffold extends StatelessWidget {
  final Widget title;
  final Widget icon;
  final Widget child;
  final Widget? floatingActionButton;

  const RoundedScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width <= Constants.smallScreenWidth;
    final scaffold = Scaffold(
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: title,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Visibility(
              visible: !isSmallScreen,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: DefaultTextStyle(
                          style: Theme.of(context).textTheme.titleLarge!,
                          child: title,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Ink(
                child: child,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
    if (!isSmallScreen) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: scaffold,
      );
    }
    return scaffold;
  }
}
