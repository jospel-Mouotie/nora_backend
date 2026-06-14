import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.padding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Déterminer le nombre de colonnes selon la largeur
        int crossAxisCount;
        double childAspectRatio;
        
        if (constraints.maxWidth < 400) {
          // Très petit écran (téléphone étroit)
          crossAxisCount = 2;
          childAspectRatio = 0.68;
        } else if (constraints.maxWidth < 600) {
          // Téléphone standard
          crossAxisCount = 2;
          childAspectRatio = 0.72;
        } else if (constraints.maxWidth < 900) {
          // Tablette
          crossAxisCount = 3;
          childAspectRatio = 0.75;
        } else {
          // Grand écran / Web
          crossAxisCount = 4;
          childAspectRatio = 0.78;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}