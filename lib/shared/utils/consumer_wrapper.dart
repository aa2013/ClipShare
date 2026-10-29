import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget consumerWrapper(Widget Function(BuildContext, WidgetRef) func) {
  return Consumer(builder: (context, ref, _) => func(context, ref));
}
