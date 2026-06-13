import 'package:flutter/material.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/core/constants/app_constants.dart';

/// Interactive chip selector for choosing a teammate's skill level.
class SkillChipSelector extends StatelessWidget {
  final String selectedSkill;
  final ValueChanged<String> onSelected;

  const SkillChipSelector({
    super.key,
    required this.selectedSkill,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: AppConstants.skillLevels.map((skill) {
        final isSelected = selectedSkill == skill;
        Color chipColor;
        
        switch (skill) {
          case AppConstants.skillBeginner:
            chipColor = Colors.green;
            break;
          case AppConstants.skillIntermediate:
            chipColor = Colors.amber;
            break;
          case AppConstants.skillAdvanced:
            chipColor = AppTheme.errorColor;
            break;
          default:
            chipColor = AppTheme.primaryColor;
        }

        return ChoiceChip(
          label: Text(skill),
          selected: isSelected,
          onSelected: (_) => onSelected(skill),
          selectedColor: chipColor,
          backgroundColor: Colors.transparent,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: chipColor),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
