import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/business_logic/character_bloc/character_bloc.dart';
import '/business_logic/favorites_bloc/favorites_bloc.dart';
import '/business_logic/theme_provider.dart';
import '/data/repositories/character_repository.dart';
import '/data/services/favorites_service.dart';
import '/presentation/app_themes.dart';
import '/presentation/screens/characters_screen.dart';
import '/presentation/screens/favorites_screen.dart';
import '/presentation/screens/settings_screen.dart';
import 'business_logic/favorites_bloc/favorites_event.dart';

class RickAndMortyApp extends StatelessWidget {
  const RickAndMortyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final characterRepository = CharacterRepository();
    final favoritesService = FavoritesService();

    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<CharacterBloc>(
                create: (context) => CharacterBloc(
                  characterRepository: characterRepository,
                  favoritesService: favoritesService,
                ),
              ),
              BlocProvider<FavoritesBloc>(
                create: (context) => FavoritesBloc(
                  characterRepository: characterRepository,
                  favoritesService: favoritesService,
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: themeProvider.themeMode,
              debugShowCheckedModeBanner: false,
              home: const MainNavigationScreen(),
            ),
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  double _indicatorPosition = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _screens = [
    const CharactersScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = const [
    'Персонажи',
    'Избранные',
    'Настройки',
  ];

  final List<IconData> _icons = const [
    Icons.people_rounded,
    CupertinoIcons.star_fill,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadThemePreference();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setTheme(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _indicatorPosition = index.toDouble();
    });

    _animationController.reset();
    _animationController.forward();

    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FavoritesBloc>().add(const FavoritesLoadEvent());
      });
    }
  }

  Widget _buildCustomBottomBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor ??
            (isDarkMode ? Colors.grey[900] : Colors.white),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left:
                    MediaQuery.of(context).size.width / 3 * _indicatorPosition +
                        MediaQuery.of(context).size.width /
                            12,
                child: Container(
                  width: MediaQuery.of(context).size.width /
                      6, 
                  height: 3, 
                  margin: const EdgeInsets.only(bottom: 56),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    color: theme.primaryColor, 
                  ),
                ),
              ),
              // Кнопки навигации
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: _NavItem(
                      icon: _icons[index],
                      label: _titles[index],
                      isSelected: _selectedIndex == index,
                      onTap: () => _onItemTapped(index),
                      animation: _animation,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                key: ValueKey<bool>(themeProvider.isDarkMode),
                themeProvider.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 24,
              ),
            ),
            onPressed: () {
              final newDarkMode = !themeProvider.isDarkMode;
              themeProvider.toggleTheme(newDarkMode);
              _saveThemePreference(newDarkMode);
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Animation<double> animation;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: isSelected
                  ? Tween<double>(begin: 1.0, end: 1.2).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                    )
                  : const AlwaysStoppedAnimation(1.0),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? theme.primaryColor
                    : theme.unselectedWidgetColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.primaryColor
                      : theme.unselectedWidgetColor.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
