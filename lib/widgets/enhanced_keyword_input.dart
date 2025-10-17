import 'package:flutter/material.dart';
import '../services/keyword_service.dart';
import '../constants/colors.dart';
import 'enhanced_keyword_display.dart';

class EnhancedKeywordInput extends StatefulWidget {
  final List<String> currentKeywords;
  final Function(List<String>) onKeywordsChanged;
  final String? hintText;
  final String? helperText;

  const EnhancedKeywordInput({
    Key? key,
    required this.currentKeywords,
    required this.onKeywordsChanged,
    this.hintText,
    this.helperText,
  }) : super(key: key);

  @override
  State<EnhancedKeywordInput> createState() => _EnhancedKeywordInputState();
}

class _EnhancedKeywordInputState extends State<EnhancedKeywordInput> {
  final TextEditingController _controller = TextEditingController();
  TextEditingController? _autocompleteController; // Store reference to Autocomplete's controller
  List<String> _suggestions = [];
  List<String> _popularKeywords = [];
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadPopularKeywords();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPopularKeywords() async {
    try {
      final popularKeywords = await KeywordService.getPopularKeywords();
      setState(() {
        _popularKeywords = popularKeywords
            .map((keyword) => keyword['keyword'] as String)
            .toList();
      });
    } catch (e) {
      print('Error loading popular keywords: $e');
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final suggestions = await KeywordService.getSuggestions(query);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoadingSuggestions = false;
      });
    }
  }

  void _addKeyword(String keyword) {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return;

    // Improved validation with better error messages
    if (trimmedKeyword.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keyword too long. Maximum 50 characters allowed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for invalid characters
    final validPattern = RegExp(r'^[a-zA-Z0-9\s\-_]+$');
    if (!validPattern.hasMatch(trimmedKeyword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keyword can only contain letters, numbers, spaces, hyphens, and underscores.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.currentKeywords.contains(trimmedKeyword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keyword already added: $trimmedKeyword'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check maximum number of keywords
    if (widget.currentKeywords.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 20 keywords allowed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newKeywords = List<String>.from(widget.currentKeywords)..add(trimmedKeyword);
    widget.onKeywordsChanged(newKeywords);
    
    // Clear both controllers to ensure the input field is cleared
    _controller.clear();
    _autocompleteController?.clear();
    
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _removeKeyword(String keyword) {
    final newKeywords = List<String>.from(widget.currentKeywords)..remove(keyword);
    widget.onKeywordsChanged(newKeywords);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keyword input field with auto-complete
        Autocomplete<String>(
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Store reference to the Autocomplete's controller
            _autocompleteController = controller;
            
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: widget.hintText ?? 'Enter key words separated by commas...',
                helperText: widget.helperText ?? 'e.g., adventurous, creative, music lover, coffee addict',
                suffixIcon: _isLoadingSuggestions
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) {
                _getSuggestions(value);
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addKeyword(value);
                }
              },
            );
          },
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _popularKeywords.take(5).toList();
            }
            return _suggestions;
          },
          onSelected: (String selection) {
            _addKeyword(selection);
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Material(
              elevation: 4.0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () {
                        onSelected(option);
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        // Current keywords display
        if (widget.currentKeywords.isNotEmpty)
          EnhancedKeywordDisplay(
            keywords: widget.currentKeywords,
            isEditing: true,
            onKeywordRemove: _removeKeyword,
            initialDisplayCount: 15,
            maxHeight: 150,
          ),
        
        const SizedBox(height: 12),
        
        // Popular keywords suggestions
        if (_popularKeywords.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Popular Keywords:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _popularKeywords.take(10).map((keyword) => ActionChip(
                  label: Text(keyword),
                  onPressed: () => _addKeyword(keyword),
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                  ),
                )).toList(),
              ),
            ],
          ),
      ],
    );
  }
} 