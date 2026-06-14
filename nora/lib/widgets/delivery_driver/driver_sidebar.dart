import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class DriverSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const DriverSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Livreur',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  index: 0,
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  isSelected: selectedIndex == 0,
                ),
                _buildMenuItem(
                  index: 1,
                  icon: Icons.assignment,
                  title: 'Mes missions',
                  isSelected: selectedIndex == 1,
                ),
                _buildMenuItem(
                  index: 2,
                  icon: Icons.monetization_on,
                  title: 'Mes gains',
                  isSelected: selectedIndex == 2,
                ),
                _buildMenuItem(
                  index: 3,
                  icon: Icons.history,
                  title: 'Historique',
                  isSelected: selectedIndex == 3,
                ),
                const Divider(),
                _buildMenuItem(
                  index: 4,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  isSelected: selectedIndex == 4,
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Jean Kamga',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'En ligne',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}