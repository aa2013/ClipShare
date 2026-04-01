import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:simple_icons/simple_icons.dart';

class LuaLibCard extends StatelessWidget {
  final RuleLib luaLib;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;
  final bool isActive;

  const LuaLibCard({
    super.key,
    required this.luaLib,
    required this.onTap,
    required this.onDeleteTap,
    this.isActive = false,
  });

  static const _activeStyle = TextStyle(
    color: Colors.blueGrey,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Icon(
                luaLib.language.icon,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      luaLib.displayName,
                      style: isActive ? _activeStyle : null,
                    ),
                    Text(
                      luaLib.libName,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
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
    );
  }
}
