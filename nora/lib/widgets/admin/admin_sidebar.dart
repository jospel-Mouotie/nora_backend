import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
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
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white),
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
                      'Administrateur',
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
                // Section Gestion du contenu
                _buildSectionTitle('Gestion du contenu'),
                _buildMenuItem(
                  index: 0,
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  isSelected: selectedIndex == 0,
                ),
                _buildMenuItem(
                  index: 1,
                  icon: Icons.store,
                  title: 'Ma boutique',
                  isSelected: selectedIndex == 1,
                ),
                _buildMenuItem(
                  index: 2,
                  icon: Icons.inventory,
                  title: 'Mes produits',
                  isSelected: selectedIndex == 2,
                ),
                _buildMenuItem(
                  index: 3,
                  icon: Icons.video_library,
                  title: 'Mes vidéos',
                  isSelected: selectedIndex == 3,
                ),
                _buildMenuItem(
                  index: 4,
                  icon: Icons.shopping_bag,
                  title: 'Commandes',
                  isSelected: selectedIndex == 4,
                ),
                _buildMenuItem(
                  index: 5,
                  icon: Icons.bar_chart,
                  title: 'Statistiques',
                  isSelected: selectedIndex == 5,
                ),
                
                const Divider(),
                
                // Section Administration
                _buildSectionTitle('Administration'),
                _buildMenuItem(
                  index: 6,
                  icon: Icons.people,
                  title: 'Utilisateurs',
                  isSelected: selectedIndex == 6,
                ),
                _buildMenuItem(
                  index: 7,
                  icon: Icons.storefront,
                  title: 'Toutes les boutiques',
                  isSelected: selectedIndex == 7,
                ),
                _buildMenuItem(
                  index: 8,
                  icon: Icons.verified,
                  title: 'Validations',
                  isSelected: selectedIndex == 8,
                ),
                _buildMenuItem(
                  index: 9,
                  icon: Icons.category,
                  title: 'Catégories',
                  isSelected: selectedIndex == 9,
                ),
                
                const Divider(),
                
                // Section Paramètres
                _buildSectionTitle('Paramètres'),
                _buildMenuItem(
                  index: 10,
                  icon: Icons.campaign,
                  title: 'Publicités',
                  isSelected: selectedIndex == 10,
                ),
                _buildMenuItem(
                  index: 11,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  isSelected: selectedIndex == 11,
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
                  child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'admin@nora.com',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isSelected,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              color: isLogout ? AppColors.error : (isSelected ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isLogout ? AppColors.error : (isSelected ? AppColors.primary : AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}