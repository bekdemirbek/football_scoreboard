import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Ortalı, büyük-harf ekran başlığı: solda (opsiyonel) geri oku,
/// sağda (opsiyonel) arama. Arama ikonuna basınca başlık yerine satır-içi
/// bir arama kutusu açılır ve [onSearchChanged] ile metni yayınlar.
class ScreenHeader extends StatefulWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.searchHint,
    this.onSearchChanged,
  });

  final String title;
  final VoidCallback? onBack;

  /// Aramayı etkinleştirir. null ise arama ikonu gösterilmez.
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;

  @override
  State<ScreenHeader> createState() => _ScreenHeaderState();
}

class _ScreenHeaderState extends State<ScreenHeader> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _searching = false;

  bool get _searchEnabled =>
      widget.searchHint != null && widget.onSearchChanged != null;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    _focus.requestFocus();
  }

  void _closeSearch() {
    _controller.clear();
    widget.onSearchChanged?.call('');
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: _searching ? _buildSearchBar() : _buildTitleBar(),
    );
  }

  Widget _buildTitleBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(widget.title.toUpperCase(), style: AppTextStyles.screenTitle),
        Align(
          alignment: Alignment.centerLeft,
          child: widget.onBack == null
              ? const SizedBox(width: 38)
              : _HeaderIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: widget.onBack!,
                ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: !_searchEnabled
              ? const SizedBox(width: 38)
              : _HeaderIconButton(
                  icon: Icons.search_rounded,
                  onTap: _openSearch,
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.accentGreen,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: widget.onSearchChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.accentGreen,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.searchHint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          _HeaderIconButton(icon: Icons.close_rounded, onTap: _closeSearch),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 17),
      ),
    );
  }
}

/// İki/üç seçenekli segment kontrolü (Süper Lig | UEFA CL gibi).
/// Görsellerdeki başlık altı sekmeler bunu kullanır.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _SegmentButton(
                label: labelOf(item),
                selected: item == selected,
                onTap: () => onSelected(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: selected ? AppGradients.greenGlow : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accentGreen.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: -3,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
