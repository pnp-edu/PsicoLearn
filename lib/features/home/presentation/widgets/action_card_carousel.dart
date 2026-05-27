import 'package:flutter/material.dart';

class ActionCardCarousel extends StatelessWidget {
  final PageController controller;
  final List<ActionCardItem> items;
  final Function(bool) onInteractionChanged;

  const ActionCardCarousel({
    super.key,
    required this.controller,
    required this.items,
    required this.onInteractionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Altura más compacta según el tamaño de pantalla
    final carouselHeight = screenHeight < 600
        ? 140.0
        : (screenWidth < 360 ? 160.0 : 190.0);

    return SizedBox(
      height: carouselHeight,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            onInteractionChanged(true);
          } else if (notification is ScrollEndNotification) {
            onInteractionChanged(false);
          }
          return false;
        },
        child: PageView.builder(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          itemBuilder: (context, index) {
            final item = items[index % items.length];

            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                double page = index.toDouble();
                if (controller.position.haveDimensions) {
                  page = controller.page ?? page;
                } else {
                  page = 1000.0;
                }

                double diff = (page - index).abs();
                double normalizedDistance = diff.clamp(0.0, 1.0);

                double scale = 1.0 - (0.15 * normalizedDistance);
                double glowOpacity =
                    (1.0 - (normalizedDistance * 1.5)).clamp(0.0, 1.0);

                final screenWidth = MediaQuery.of(context).size.width;
                final cardWidth = screenWidth * 0.45;
                final cardHeight = cardWidth * 0.95;

                return Padding(
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: item.onTap,
                        child: Container(
                          width: cardWidth,
                          height: cardHeight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: item.color
                                  .withOpacity((0.2 + (0.6 * glowOpacity)).clamp(0.0, 1.0)),
                              width: 1.5 + (1.0 * glowOpacity),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withOpacity(
                                    (0.05 + (0.2 * glowOpacity)).clamp(0.0, 1.0)),
                                blurRadius: 12 + (18 * glowOpacity),
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ColorFiltered(
                            colorFilter: item.isLocked 
                              ? const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      1, 0,
                                ])
                              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            item.color,
                                            item.color.withOpacity(0.6)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Hero(
                                        tag: 'card_icon_${item.title}',
                                        child: Icon(item.icon,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                    Icon(
                                      item.isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                                      color: item.color.withOpacity(
                                          (0.4 + (0.4 * glowOpacity)).clamp(0.0, 1.0)),
                                      size: 11,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: item.color,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ActionCardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLocked;

  ActionCardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLocked = false,
  });
}
