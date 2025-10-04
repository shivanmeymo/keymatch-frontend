import 'package:flutter/material.dart';
import 'package:key_match/constants/colors.dart';

class EnhancedKeywordDisplay extends StatefulWidget {
  final List<String> keywords;
  final bool isEditing;
  final Function(String)? onKeywordTap;
  final Function(String)? onKeywordRemove;
  final int initialDisplayCount;
  final double maxHeight;

  const EnhancedKeywordDisplay({
    super.key,
    required this.keywords,
    this.isEditing = false,
    this.onKeywordTap,
    this.onKeywordRemove,
    this.initialDisplayCount = 12,
    this.maxHeight = 200,
  });

  @override
  State<EnhancedKeywordDisplay> createState() => _EnhancedKeywordDisplayState();
}

class _EnhancedKeywordDisplayState extends State<EnhancedKeywordDisplay> {
  bool _isExpanded = false;
  String _searchQuery = '';
  late List<String> _filteredKeywords;

  @override
  void initState() {
    super.initState();
    _filteredKeywords = List.from(widget.keywords);
  }

  @override
  void didUpdateWidget(EnhancedKeywordDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keywords != widget.keywords) {
      _filterKeywords();
    }
  }

  void _filterKeywords() {
    if (_searchQuery.isEmpty) {
      _filteredKeywords = List.from(widget.keywords);
    } else {
      _filteredKeywords = widget.keywords
          .where((keyword) => keyword.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.keywords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'No keywords yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar for large keyword lists
        if (widget.keywords.length > 20)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterKeywords();
              },
              decoration: InputDecoration(
                hintText: 'Search keywords...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterKeywords();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryGreen),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),

        // Keyword count indicator
        if (widget.keywords.length > 10)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.tag, color: AppColors.primaryGreen, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_filteredKeywords.length} keywords',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Text(
                    ' (filtered)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

        // Keywords grid
        Container(
          constraints: BoxConstraints(
            maxHeight: _isExpanded ? double.infinity : widget.maxHeight,
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _buildKeywordChips(),
            ),
          ),
        ),

        // Show more/less button
        if (widget.keywords.length > widget.initialDisplayCount)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: _toggleExpanded,
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
                label: Text(
                  _isExpanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildKeywordChips() {
    final displayKeywords = _isExpanded 
        ? _filteredKeywords 
        : _filteredKeywords.take(widget.initialDisplayCount).toList();

    return displayKeywords.map((keyword) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGreenLightest),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onKeywordTap != null ? () => widget.onKeywordTap!(keyword) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      keyword,
                      style: const TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isEditing && widget.onKeywordRemove != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => widget.onKeywordRemove!(keyword),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
} 