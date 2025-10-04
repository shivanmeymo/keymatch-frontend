import 'package:flutter/material.dart';

enum ThemedTextType {
  defaultType,
  title,
  defaultSemiBold,
  subtitle,
  link,
}

class ThemedText extends StatelessWidget {
  final String text;
  final ThemedTextType type;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ThemedText(
    this.text, {
    this.type = ThemedTextType.defaultType,
    this.style,
    this.textAlign,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onBackground,
    ) ?? const TextStyle(); // Provide a fallback TextStyle

    TextStyle specificStyle;

    switch (type) {
      case ThemedTextType.defaultType:
        specificStyle = defaultStyle.copyWith(
          fontSize: 16,
          height: 24 / 16, // Line height divided by font size
        );
        break;
      case ThemedTextType.defaultSemiBold:
        specificStyle = defaultStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 24 / 16,
        );
        break;
      case ThemedTextType.title:
        // Using displayLarge as a base for title, then customizing
        specificStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          color: Theme.of(context).colorScheme.onBackground, // Ensure color adapts
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 32 / 32,
        ) ?? defaultStyle.copyWith( // Fallback if displayLarge is null
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 32 / 32,
        );
        break;
      case ThemedTextType.subtitle:
        // Using headlineMedium as a base for subtitle, then customizing
        specificStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onBackground, // Ensure color adapts
          fontSize: 20,
          fontWeight: FontWeight.bold,
          // Flutter's TextStyle 'height' is a multiplier of the font size.
          // If a specific line-height pixel value is given and it's different from fontSize,
          // calculate height: desiredLineHeightInPixels / fontSize
          // For subtitle, if no specific line height is given, we can omit or set to e.g. 1.2 for some spacing
          height: 1.2, // Example, adjust if specific line height is needed
        ) ?? defaultStyle.copyWith( // Fallback if headlineMedium is null
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.2,
        );
        break;
      case ThemedTextType.link:
        specificStyle = defaultStyle.copyWith(
          fontSize: 16,
          color: Colors.blue, // Default blue for links
          height: 30 / 16,
          // Links often have underlines, but not specified in requirements
          // decoration: TextDecoration.underline,
          // decorationColor: Colors.blue,
        );
        break;
      default:
        specificStyle = defaultStyle.copyWith(
          fontSize: 16,
          height: 24 / 16,
        );
        break;
    }

    // Merge with the optional style parameter if provided
    final TextStyle finalStyle = specificStyle.merge(style);

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
    );
  }
}
