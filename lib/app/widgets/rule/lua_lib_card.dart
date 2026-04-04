import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:simple_icons/simple_icons.dart';

class LuaLibCard extends StatelessWidget {
  final RuleLib luaLib;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;
  final bool isActive;

  static final _borderRadius = BorderRadius.circular(12.0);

  const LuaLibCard({
    super.key,
    required this.luaLib,
    required this.onTap,
    required this.onDeleteTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final duration = 200.ms;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: AnimatedContainer(
          duration: duration,
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.blueGrey : Colors.white,
              width: 2,
            ),
            borderRadius: _borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  luaLib.language.icon,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: duration,
                        style: TextStyle(
                          fontSize: 17,
                          color: isActive ? Colors.blueGrey : Theme.of(context).textTheme.bodyMedium!.color,
                          fontWeight: isActive ? FontWeight.bold : null,
                        ),
                        child: Text(luaLib.displayName),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        luaLib.libName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDeleteTap,
                  tooltip: TranslationKey.delete.tr,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
