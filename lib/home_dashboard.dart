import 'package:flutter/material.dart';
import 'climate_screen.dart';
import 'scanner_screen.dart';
// import 'history_screen.dart';
import 'localization_helper.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    // ListenableBuilder ensures the home dashboard rebuilds instantly on language toggle
    return ListenableBuilder(
      listenable: LocalizationHelper.instance,
      builder: (context, child) {
        final localization = LocalizationHelper.instance;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F6F3),
          appBar: AppBar(
            title: Text(
              localization.translate('app_title'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: 0.5),
            ),
            backgroundColor: const Color(0xFF1B4D3E),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              // Language Toggle Button (EN / HI)
              TextButton.icon(
                onPressed: () {
                  localization.toggleLanguage();
                },
                icon: const Icon(Icons.language_rounded, color: Colors.white, size: 18),
                label: Text(
                  localization.currentLang.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              // IconButton(
              //   tooltip: localization.translate('history_tooltip'),
              //   icon: const Icon(Icons.history_rounded),
              //   onPressed: () => Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (_) => const HistoryScreen()),
              //   ),
              // ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroCard(localization),
                  const SizedBox(height: 22),
                  Text(
                    localization.translate('smart_agri_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B4D3E),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    localization.translate('smart_agri_desc'),
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _featureCard(
                    context,
                    icon: Icons.document_scanner_rounded,
                    title: localization.translate('scanner_title_text'),
                    subtitle: localization.translate('scanner_sub_text'),
                    color: Colors.green,
                    accentColor: const Color(0xFF2E7D32),
                    page: const ScannerScreen(),
                  ),
                  const SizedBox(height: 12),
                  _featureCard(
                    context,
                    icon: Icons.sensors_rounded,
                    title: localization.translate('climate_title_text'),
                    subtitle: localization.translate('climate_sub_text'),
                    color: Colors.blue,
                    accentColor: const Color(0xFF1565C0),
                    page: const ClimateScreen(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(LocalizationHelper localization) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF2C6B56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.translate('hero_main_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localization.translate('hero_main_sub'),
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.45,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
    required Color accentColor,
    required Widget page,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}