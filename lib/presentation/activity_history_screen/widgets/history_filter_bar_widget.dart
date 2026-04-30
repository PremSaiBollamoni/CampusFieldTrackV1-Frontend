import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HistoryFilterBarWidget extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final Function(int) onFilterSelected;

  const HistoryFilterBarWidget({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = selectedIndex == i;
          return GestureDetector(
            onTap: () => onFilterSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 210),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.glassBorder,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(77),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filters[i],
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppTheme.onDarkMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
