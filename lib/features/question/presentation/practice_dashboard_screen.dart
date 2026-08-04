import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fl_chart/fl_chart.dart';
import 'practice_notifier.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/domain/profile_model.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../leaderboard/domain/leaderboard_model.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../academics/data/academics_repository.dart';
import '../../ai/presentation/progga_ai_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

final activeBannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.dio.get('/banners');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
  } catch (_) {}
  return [];
});

class PracticeDashboardScreen extends ConsumerStatefulWidget {
  const PracticeDashboardScreen({super.key});

  @override
  ConsumerState<PracticeDashboardScreen> createState() => _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends ConsumerState<PracticeDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(practiceProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(practiceProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final leaderboardAsync = ref.watch(myLeaderboardProvider);
    final bannersAsync = ref.watch(activeBannersProvider);


    if (profileAsync.isLoading && profileAsync.value == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF017A47)),
        ),
      );
    }

    if (profileAsync is AsyncError) {
      final error = profileAsync.error;
      if (error is NetworkException && error.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    // Redirect to onboarding if not set up yet
    if (profileAsync.value != null) {
      final userData = profileAsync.value!;
      if (userData.profile?.className == null || userData.profile!.className!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/onboarding');
        });
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    final theme = Theme.of(context);

    // List of page view bodies matching each bottom navigation index
    final List<Widget> views = [
      _buildHomeDashboardView(state, theme, profileAsync, leaderboardAsync),
      _buildQuestionBankView(theme),
      _buildExamListView(theme),
      const ProggaAiScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentNavIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leadingWidth: 90,
              // Left: Streak counter widget showing 🔥 ১ matching the screenshot
              leading: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0ECE6), // Light theme green tint of rgb(1, 122, 71)
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFB9D8C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          '''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M12.832 21.801c3.126-.626 7.168-2.875 7.168-8.69c0-5.291-3.873-8.815-6.658-10.434c-.619-.36-1.342.113-1.342.828v1.828c0 1.442-.606 4.074-2.29 5.169c-.86.559-1.79-.278-1.894-1.298l-.086-.838c-.1-.974-1.092-1.565-1.87-.971C4.461 8.46 3 10.33 3 13.11C3 20.221 8.289 22 10.933 22q.232 0 .484-.015C10.111 21.874 8 21.064 8 18.444c0-2.05 1.495-3.435 2.631-4.11c.306-.18.663.055.663.41v.59c0 .45.175 1.155.59 1.637c.47.546 1.159-.026 1.214-.744c.018-.226.246-.37.442-.256c.641.375 1.46 1.175 1.46 2.473c0 2.048-1.129 2.99-2.168 3.357" />
</svg>''',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(Color(0xFFFFB300), BlendMode.srcIn),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profileAsync.maybeWhen(
                            data: (user) => '${user.profile?.currentStreak ?? 1}',
                            orElse: () => '১',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF017A47),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const SizedBox.shrink(),
              // Right: Circular profile avatar image
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      context.push('/profile');
                    },
                    child: Hero(
                      tag: 'user_avatar_hero',
                      child: CustomAvatar(
                        avatarUrl: profileAsync.value?.profile?.avatarKey,
                        radius: 18,
                        backgroundColor: const Color(0xFFF18881),
                        fallbackWidget: const Text(
                          '👨‍🎓',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : (_currentNavIndex == 4 || _currentNavIndex == 3
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    _currentNavIndex == 1 ? 'প্রশ্নব্যাংক' : 'মক পরীক্ষা',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                )),
      body: IndexedStack(
        index: _currentNavIndex,
        children: views,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE0ECE6), // Light theme green tint capsule
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                size: 30, // Increased size for selected tab
                color: Color(0xFF017A47),
              );
            }
            return const IconThemeData(
              size: 27, // Increased size for unselected tab
              color: Color(0xFF495057),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 13, // Increased font size
                fontWeight: FontWeight.bold,
                color: Color(0xFF017A47),
              );
            }
            return const TextStyle(
              fontSize: 12.5, // Increased font size
              fontWeight: FontWeight.w500,
              color: Color(0xFF495057),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="29" height="29" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M9.447 15.398a.75.75 0 1 0-.894 1.204A5.77 5.77 0 0 0 12 17.75a5.77 5.77 0 0 0 3.447-1.148a.75.75 0 1 0-.894-1.204A4.27 4.27 0 0 1 12 16.25a4.27 4.27 0 0 1-2.553-.852" />
	<path fill="currentColor" fill-rule="evenodd" d="M12 1.25c-.708 0-1.351.203-2.05.542c-.674.328-1.454.812-2.427 1.416L5.456 4.491c-.92.572-1.659 1.03-2.227 1.465c-.589.45-1.041.91-1.368 1.507c-.326.595-.472 1.229-.543 1.978c-.068.725-.068 1.613-.068 2.726v1.613c0 1.904 0 3.407.153 4.582c.156 1.205.486 2.178 1.23 2.947c.747.773 1.697 1.119 2.875 1.282c1.14.159 2.598.159 4.434.159h4.116c1.836 0 3.294 0 4.434-.159c1.177-.163 2.128-.509 2.876-1.282c.743-.769 1.073-1.742 1.23-2.947c.152-1.175.152-2.678.152-4.582v-1.613c0-1.113 0-2-.068-2.726c-.07-.75-.217-1.383-.543-1.978c-.327-.597-.78-1.056-1.368-1.507c-.568-.436-1.306-.893-2.227-1.465l-2.067-1.283c-.973-.604-1.753-1.088-2.428-1.416c-.697-.34-1.34-.542-2.049-.542M8.28 4.504c1.015-.63 1.73-1.072 2.327-1.363c.581-.283.993-.391 1.393-.391s.812.108 1.393.391c.598.29 1.312.733 2.327 1.363l2 1.241c.961.597 1.636 1.016 2.14 1.402c.489.375.77.684.963 1.036c.193.353.306.766.365 1.398c.061.648.062 1.465.062 2.623v1.521c0 1.97-.002 3.376-.14 4.443c-.136 1.048-.393 1.656-.82 2.099c-.425.439-1.003.7-2.004.839c-1.026.142-2.379.144-4.286.144h-4c-1.908 0-3.26-.002-4.286-.144c-1.001-.14-1.579-.4-2.003-.84c-.428-.442-.685-1.05-.82-2.098c-.14-1.067-.141-2.472-.141-4.443v-1.521c0-1.158 0-1.975.062-2.623c.059-.632.172-1.045.365-1.398c.193-.352.474-.661.964-1.036c.503-.386 1.178-.805 2.139-1.402z" clip-rule="evenodd" />
</svg>''',
                width: 29,
                height: 29,
                colorFilter: const ColorFilter.mode(Color(0xFF495057), BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" fill-rule="evenodd" d="M2.52 7.823C2 8.77 2 9.915 2 12.203v1.522c0 3.9 0 5.851 1.172 7.063S6.229 22 10 22h4c3.771 0 5.657 0 6.828-1.212S22 17.626 22 13.725v-1.521c0-2.289 0-3.433-.52-4.381c-.518-.949-1.467-1.537-3.364-2.715l-2-1.241C14.111 2.622 13.108 2 12 2s-2.11.622-4.116 1.867l-2 1.241C3.987 6.286 3.038 6.874 2.519 7.823m6.927 7.575a.75.75 0 1 0-.894 1.204A5.77 5.77 0 0 0 12 17.75a5.77 5.77 0 0 0 3.447-1.148a.75.75 0 1 0-.894-1.204A4.27 4.27 0 0 1 12 16.25a4.27 4.27 0 0 1-2.553-.852" clip-rule="evenodd" />
</svg>''',
                width: 35,
                height: 35,
                colorFilter: const ColorFilter.mode(Color(0xFF017A47), BlendMode.srcIn),
              ),
              label: 'হোম',
            ),
            NavigationDestination(
              icon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="27" height="27" viewBox="0 0 56 56">
	<path d="M0 0h56v56H0z" fill="none" />
	<path fill="currentColor" d="M15.144 49.574H40.88c4.593 0 7.054-2.39 7.054-6.984V19.246c2.274-.375 3.493-2.086 3.493-4.594V11.09c0-2.86-1.57-4.664-4.454-4.664H9.027c-2.742 0-4.453 1.804-4.453 4.664v3.562c0 2.508 1.242 4.22 3.492 4.594V42.59c0 4.617 2.485 6.984 7.078 6.984M9.988 15.777c-1.172 0-1.64-.492-1.64-1.664V11.63c0-1.172.468-1.664 1.64-1.664h36.047c1.195 0 1.617.492 1.617 1.664v2.484c0 1.172-.422 1.664-1.617 1.664Zm5.133 30.258c-2.11 0-3.281-1.148-3.281-3.258v-23.46h32.32v23.46c0 2.11-1.172 3.258-3.258 3.258Zm5.156-17.273H35.77c.961 0 1.665-.68 1.665-1.711v-.75c0-1.031-.704-1.688-1.665-1.688H20.277c-.984 0-1.664.657-1.664 1.688v.75c0 1.031.68 1.71 1.664 1.71" />
</svg>''',
                width: 27,
                height: 27,
                colorFilter: const ColorFilter.mode(Color(0xFF495057), BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 56 56">
	<path d="M0 0h56v56H0z" fill="none" />
	<path fill="currentColor" d="M8.559 16.95H47.44c2.649 0 3.985-1.571 3.985-4.196V10.62c0-2.625-1.336-4.195-3.985-4.195H8.56c-2.508 0-3.985 1.57-3.985 4.195v2.133c0 2.625 1.336 4.195 3.985 4.195m6.585 32.624H40.88c4.593 0 7.054-2.39 7.054-6.984V20.16H8.066v22.43c0 4.617 2.485 6.984 7.078 6.984m5.133-20.953c-.984 0-1.664-.68-1.664-1.71v-.727c0-1.032.68-1.688 1.664-1.688H35.77c.961 0 1.665.656 1.665 1.688v.726c0 1.031-.704 1.711-1.665 1.711Z" />
</svg>''',
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(Color(0xFF017A47), BlendMode.srcIn),
              ),
              label: 'প্রশ্নব্যাংক',
            ),
            NavigationDestination(
              icon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="27" height="27" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="1.5">
		<path d="M2 12c0 4.714 0 7.071 1.464 8.535C4.93 22 7.286 22 12 22s7.071 0 8.535-1.465C22 19.072 22 16.714 22 12v-1.5M13.5 2H12C7.286 2 4.929 2 3.464 3.464c-.973.974-1.3 2.343-1.409 4.536" />
		<path d="m16.652 3.455l.649-.649A2.753 2.753 0 0 1 21.194 6.7l-.65.649m-3.892-3.893s.081 1.379 1.298 2.595c1.216 1.217 2.595 1.298 2.595 1.298m-3.893-3.893L10.687 9.42c-.404.404-.606.606-.78.829q-.308.395-.524.848c-.121.255-.211.526-.392 1.068L8.412 13.9m12.133-6.552l-2.983 2.982m-2.982 2.983c-.404.404-.606.606-.829.78a4.6 4.6 0 0 1-.848.524c-.255.121-.526.211-1.068.392l-1.735.579m0 0l-1.123.374a.742.742 0 0 1-.939-.94l.374-1.122m1.688 1.688L8.412 13.9" />
	</g>
</svg>''',
                width: 27,
                height: 27,
                colorFilter: const ColorFilter.mode(Color(0xFF495057), BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M21.194 2.806a2.753 2.753 0 0 1 0 3.893l-.496.496a5 5 0 0 1-.533-.151a5.2 5.2 0 0 1-1.968-1.241a5.2 5.2 0 0 1-1.241-1.968a5 5 0 0 1-.15-.533l.495-.496a2.753 2.753 0 0 1 3.893 0M14.58 13.313c-.404.404-.606.606-.829.78a4.6 4.6 0 0 1-.848.524c-.255.121-.526.211-1.068.392l-2.858.953a.742.742 0 0 1-.939-.94l.953-2.857c.18-.542.27-.813.392-1.068q.217-.453.524-.848c.174-.223.376-.425.78-.83l4.916-4.915a6.7 6.7 0 0 0 1.533 2.36a6.7 6.7 0 0 0 2.36 1.533z" />
	<path fill="currentColor" d="M20.536 20.536C22 19.07 22 16.714 22 12c0-1.548 0-2.842-.052-3.934l-6.362 6.362c-.351.352-.615.616-.912.847a6 6 0 0 1-1.125.696c-.34.162-.694.28-1.166.437l-2.932.977a2.242 2.242 0 0 1-2.836-2.836l.977-2.932c.157-.472.275-.826.437-1.166q.287-.6.696-1.125c.231-.297.495-.56.847-.912l6.362-6.362C14.842 2 13.548 2 12 2C7.286 2 4.929 2 3.464 3.464C2 4.93 2 7.286 2 12s0 7.071 1.464 8.535C4.93 22 7.286 22 12 22s7.071 0 8.535-1.465" />
</svg>''',
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(Color(0xFF017A47), BlendMode.srcIn),
              ),
              label: 'পরীক্ষা',
            ),
            NavigationDestination(
              icon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="27" height="27" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 11h6m-6 4h3m1-12h-1a9 9 0 0 0-9 9v8a1 1 0 0 0 1 1h8a9 9 0 0 0 9-9v-1m-2-9l.13.378a4 4 0 0 0 2.492 2.493L22 5l-.378.13a4 4 0 0 0-2.493 2.492L19 8l-.13-.378a4 4 0 0 0-2.492-2.493L16 5l.378-.13a4 4 0 0 0 2.493-2.492z" />
</svg>''',
                width: 27,
                height: 27,
                colorFilter: const ColorFilter.mode(Color(0xFF495057), BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M12 2c.901 0 1.774.12 2.605.344a3 3 0 0 0 .425 5.495l.378.129a1 1 0 0 1 .624.624l.13.378a3 3 0 0 0 5.493.425A10 10 0 0 1 22 12c0 5.523-4.477 10-10 10H4a2 2 0 0 1-2-2v-8C2 6.477 6.477 2 12 2M9 14a1 1 0 1 0 0 2h3a1 1 0 1 0 0-2zm0-4a1 1 0 1 0 0 2h6a1 1 0 1 0 0-2zm10-9a1 1 0 0 1 .946.677l.13.378c.3.879.99 1.57 1.87 1.87l.377.129a1 1 0 0 1 0 1.892l-.378.13c-.879.3-1.57.99-1.87 1.87l-.129.377a1 1 0 0 1-1.892 0l-.13-.378a3 3 0 0 0-1.87-1.87l-.377-.129a1 1 0 0 1 0-1.892l.378-.13c.879-.3 1.57-.99 1.87-1.87l.129-.377A1 1 0 0 1 19 1" />
</svg>''',
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(Color(0xFF017A47), BlendMode.srcIn),
              ),
              label: 'প্রজ্ঞা এআই',
            ),
            NavigationDestination(
              icon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="27" height="27" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" fill-rule="evenodd" d="M12 1.25a4.75 4.75 0 1 0 0 9.5a4.75 4.75 0 0 0 0-9.5M8.75 6a3.25 3.25 0 1 1 6.5 0a3.25 3.25 0 0 1-6.5 0M12 12.25c-2.313 0-4.445.526-6.024 1.414C4.42 14.54 3.25 15.866 3.25 17.5v.102c-.001 1.162-.002 2.62 1.277 3.662c.629.512 1.51.877 2.7 1.117c1.192.242 2.747.369 4.773.369s3.58-.127 4.774-.369c1.19-.24 2.07-.605 2.7-1.117c1.279-1.042 1.277-2.5 1.276-3.662V17.5c0-1.634-1.17-2.96-2.725-3.836c-1.58-.888-3.711-1.414-6.025-1.414M4.75 17.5c0-.851.622-1.775 1.961-2.528c1.316-.74 3.184-1.222 5.29-1.222c2.104 0 3.972.482 5.288 1.222c1.34.753 1.961 1.677 1.961 2.528c0 1.308-.04 2.044-.724 2.6c-.37.302-.99.597-2.05.811c-1.057.214-2.502.339-4.476.339s-3.42-.125-4.476-.339c-1.06-.214-1.68-.509-2.05-.81c-.684-.557-.724-1.293-.724-2.601" clip-rule="evenodd" />
</svg>''',
                width: 27,
                height: 27,
                colorFilter: const ColorFilter.mode(Color(0xFF495057), BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<circle cx="12" cy="6" r="4" fill="currentColor" />
	<path fill="currentColor" d="M20 17.5c0 2.485 0 4.5-8 4.5s-8-2.015-8-4.5S7.582 13 12 13s8 2.015 8 4.5" />
</svg>''',
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(Color(0xFF017A47), BlendMode.srcIn),
              ),
              label: 'প্রোফাইল',
            ),
          ],
        ),
      ),
    );
  }

  // View 0: Home Dashboard matching the new screenshot
  Widget _buildHomeDashboardView(state, ThemeData theme, profileAsync, leaderboardAsync) {
    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;
    final bannersAsync = ref.watch(activeBannersProvider);


    // Read league name dynamically from active user's entry in the leaderboard list if found
    String leagueName = 'আয়রন লীগ';
    int currentXp = profile?.xp ?? 0;
    if (leaderboardAsync.value != null && myUserId != null) {
      final myEntry = leaderboardAsync.value!.firstWhere(
        (e) => e.userId == myUserId,
        orElse: () => LeaderboardEntryModel(
          rank: 0,
          userId: '',
          username: '',
          fullName: '',
          xp: currentXp,
          level: profile?.level ?? 1,
          solvedQuestionsCount: 0,
          league: 'IRON',
        ),
      );
      if (myEntry.xp > 0) currentXp = myEntry.xp;
    }

    if (currentXp >= 5000) {
      leagueName = 'ইনফিনিটি লীগ';
    } else if (currentXp >= 3000) {
      leagueName = 'ডায়মন্ড লীগ';
    } else if (currentXp >= 1500) {
      leagueName = 'গোল্ড লীগ';
    } else if (currentXp >= 800) {
      leagueName = 'সিলভার লীগ';
    } else if (currentXp >= 300) {
      leagueName = 'ব্রোঞ্জ লীগ';
    } else {
      leagueName = 'আয়রন লীগ';
    }

    final userName = profile?.fullName ?? 'Rabbi failure';
    final userScore = profile?.xp ?? 3981;
    final starPoints = profile != null ? (profile.xp % 100) : 0;
    final progressVal = profile != null ? (profile.xp % 100) / 100.0 : 0.0;
    return RefreshIndicator(
      color: const Color(0xFF017A47),
      onRefresh: () async {
        try {
          await Future.wait([
            ref.refresh(userProfileProvider.future),
            ref.refresh(myLeaderboardProvider.future),
            ref.refresh(activeBannersProvider.future),
          ]);
        } catch (_) {}
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // 1. Promo Banners Carousel Slider
          bannersAsync.when(
            data: (banners) => banners.isNotEmpty
                ? BannerSliderWidget(banners: banners)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 2. Clean Action Grid Buttons Row of 4 items (Icon + Label)

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                _buildGridAction(
                  iconWidget: _buildImageIconAsset('assets/icons/qsbank.png', Icons.inventory_2_outlined),
                  label: 'প্রশ্নব্যাংক',
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                _buildGridAction(
                  iconWidget: _buildImageIconAsset('assets/icons/exam.png', Icons.edit_note_outlined),
                  label: 'মক পরীক্ষা',
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
                _buildGridAction(
                  iconWidget: _buildImageIconAsset('assets/icons/report.png', Icons.bar_chart_outlined),
                  label: 'রিপোর্ট',
                  onTap: () => setState(() => _currentNavIndex = 3),
                ),
                _buildGridAction(
                  iconWidget: _buildImageIconAsset('assets/icons/ai.png', Icons.psychology_outlined),
                  label: 'Progga AI',
                  onTap: () => context.push('/progga-ai'),
                ),
              ],
            ),
          ),

          // 3. Active Leaderboard Section matching the new screenshot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECEFF1), width: 1.2),
              ),
              child: Column(
                children: [
                  // Leaderboard header title row
                  InkWell(
                    onTap: () => context.push('/leaderboard'),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'লিডারবোর্ড',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF017A47).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  leagueName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF017A47),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'সবগুলো দেখুন',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF017A47),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF017A47)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Star progress track bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECEFF1)),
                      ),
                      child: Row(
                        children: [
                          Text('$starPoints XP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF017A47))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressVal,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Leaderboard list items loaded from API
                  if (leaderboardAsync is AsyncLoading && (leaderboardAsync.value == null || leaderboardAsync.value!.isEmpty)) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF017A47))),
                    ),
                  ] else if (leaderboardAsync is AsyncError || leaderboardAsync.value == null) ...[
                    _buildLeaderboardRow(
                      name: userName,
                      score: userScore,
                      avatarText: '😎',
                      avatarBg: const Color(0xFF81C784),
                      isCurrentUser: true,
                    ),
                  ] else ...[
                    Builder(
                      builder: (context) {
                        final entries = leaderboardAsync.value!;
                        // Convert entries to LeaderboardPlayer models
                        final List<LeaderboardPlayer> allPlayers = entries.map<LeaderboardPlayer>((e) {
                          final isMe = e.userId == myUserId;
                          // Use actual avatar URL if available; else show first letter of name
                          final avatarDisplay = e.avatarKey != null && e.avatarKey!.isNotEmpty
                              ? e.avatarKey!
                              : (e.fullName.isNotEmpty ? e.fullName[0].toUpperCase() : '?');
                          return LeaderboardPlayer(
                            name: e.fullName.isNotEmpty ? e.fullName : e.username,
                            score: e.xp,
                            avatarText: avatarDisplay,
                            avatarBg: isMe ? const Color(0xFF81C784) : const Color(0xFF26A69A),
                            isCurrentUser: isMe,
                          );
                        }).toList();

                        // If current user is not in the global ZSET list yet, insert them
                        final hasMe = allPlayers.any((p) => p.isCurrentUser);
                        if (!hasMe && profile != null) {
                          allPlayers.add(
                            LeaderboardPlayer(
                              name: userName,
                              score: userScore,
                              avatarText: '😎',
                              avatarBg: const Color(0xFF81C784),
                              isCurrentUser: true,
                            ),
                          );
                        }

                        // Sort players by score
                        allPlayers.sort((a, b) => b.score.compareTo(a.score));
                        int myIndex = allPlayers.indexWhere((p) => p.isCurrentUser);

                        List<LeaderboardPlayer> displayPlayers = [];
                        if (allPlayers.length < 3) {
                          displayPlayers = allPlayers.where((p) => p.isCurrentUser).toList();
                        } else if (myIndex == 0) {
                          displayPlayers = [allPlayers[0], allPlayers[1], allPlayers[2]];
                        } else if (myIndex == allPlayers.length - 1) {
                          displayPlayers = [allPlayers[myIndex - 2], allPlayers[myIndex - 1], allPlayers[myIndex]];
                        } else if (myIndex != -1) {
                          displayPlayers = [allPlayers[myIndex - 1], allPlayers[myIndex], allPlayers[myIndex + 1]];
                        } else {
                          displayPlayers = allPlayers.take(3).toList();
                        }

                        return Column(
                          children: [
                            ...displayPlayers.map((player) {
                              return _buildLeaderboardRow(
                                name: player.name,
                                score: player.score,
                                avatarText: player.avatarText,
                                avatarBg: player.avatarBg,
                                isCurrentUser: player.isCurrentUser,
                              );
                            }),
                          ],
                        );
                      }
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ), // end SingleChildScrollView
    ); // end RefreshIndicator
  }

  Widget _buildImageIconAsset(String assetPath, IconData fallbackIcon) {
    return Image.asset(
      assetPath,
      width: 56,
      height: 56,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: 48, color: const Color(0xFF017A47));
      },
    );
  }

  Widget _buildGridAction({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Row helper for building individual leaderboard entries
  Widget _buildLeaderboardRow({
    required String name,
    required int score,
    required String avatarText,
    required Color avatarBg,
    required bool isCurrentUser,
  }) {
    final bool isUrl = avatarText.startsWith('http') || avatarText.startsWith('https');
    final bool isSingleChar = avatarText.length == 1;

    return InkWell(
      onTap: () => context.push('/leaderboard'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFF017A47).withValues(alpha: 0.08) : Colors.transparent,
          border: isCurrentUser
              ? const Border(left: BorderSide(color: Color(0xFF017A47), width: 4))
              : null,
        ),
        child: Row(
          children: [
            isUrl
                ? CustomAvatar(
                    avatarUrl: avatarText,
                    radius: 20,
                    backgroundColor: avatarBg,
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarBg,
                    child: Text(
                      isSingleChar ? avatarText : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  color: isCurrentUser ? const Color(0xFF017A47) : Colors.black87,
                ),
              ),
            ),
            Text(
              '$score XP',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF017A47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View 1: Question Bank View (Dynamic for User Class & Group)
  Widget _buildQuestionBankView(ThemeData theme) {
    final profile = ref.watch(userProfileProvider).value?.profile;
    final className = profile?.className ?? 'HSC 2026';
    final groupName = profile?.batch ?? profile?.targetExam ?? 'বিজ্ঞান';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Class & Group Dynamic Filter Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF017A47).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF017A47).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: Color(0xFF017A47)),
                    const SizedBox(width: 6),
                    Text(
                      '$className • $groupName',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF017A47),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: const Text(
                    'ফিল্টার বদলান ➔',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF017A47),
                    ),
                  ),
                ),
              ],
            ),
          ),

          TextField(
            decoration: InputDecoration(
              hintText: '$className - $groupName প্রশ্ন খুঁজুন...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                final titles = [
                  'কিসের মানের পরিবর্তনের জন্য লেন্সের ফোকাস দূরত্ব পরিবর্তিত হয়?',
                  'নিচের কোনটি লরেন্টজ বলের সঠিক সমীকরণ?',
                  'একটি তারের রোধ ১০ ওহম হলে তারটি টেনে দ্বিগুণ করলে রোধ কত হবে?',
                  'স্থির তড়িৎক্ষেত্রে অসীম থেকে একটি আধানকে আনতে কৃতকাজ কী?'
                ];
                final subjects = ['পদার্থবিজ্ঞান', 'পদার্থবিজ্ঞান', 'পদার্থবিজ্ঞান', 'পদার্থবিজ্ঞান'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('$className • ${subjects[index]}', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // View 2: Mock Exam List View (Dynamic for User Class & Group)
  Widget _buildExamListView(ThemeData theme) {
    final profile = ref.watch(userProfileProvider).value?.profile;
    final className = profile?.className ?? 'HSC 2026';
    final groupName = profile?.batch ?? profile?.targetExam ?? 'বিজ্ঞান';

    final curriculumAsync = ref.watch(studentCurriculumProvider);

    return curriculumAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF017A47)),
            SizedBox(height: 12),
            Text(
              'আপনার বিষয়ের পরীক্ষা প্রস্তুত হচ্ছে...',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                'পরীক্ষা লোড করতে সমস্যা হয়েছে: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(studentCurriculumProvider),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF017A47)),
                child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  Text(
                    '$className ($groupName)-এর জন্য কোনো বিষয় পাওয়া যায়নি।',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'প্রোফাইল থেকে অন্য বিষয়/ক্লাস নির্বাচন করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/profile'),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('ক্লাস পরিবর্তন করুন', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF017A47)),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 6,
            childAspectRatio: 3.2,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index] as Map<String, dynamic>;
            final subjectName = subject['name'] ?? 'বিষয়';
            final rawIcon = subject['icon'] as String?;
            final rawImageUrl = subject['imageUrl'] as String?;
            final chapters = (subject['chapters'] as List<dynamic>?) ?? [];

            // Prioritize icon image URL over subject banner image
            final iconImageUrl = (rawIcon != null && (rawIcon.startsWith('http://') || rawIcon.startsWith('https://')))
                ? rawIcon
                : ((rawImageUrl != null && rawImageUrl.isNotEmpty && (rawImageUrl.startsWith('http://') || rawImageUrl.startsWith('https://')))
                    ? rawImageUrl
                    : null);
            final emojiIcon = (rawIcon != null && !rawIcon.startsWith('http')) ? rawIcon : '📚';

            return Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: const Color(0xFF017A47).withOpacity(0.12),
                highlightColor: const Color(0xFF017A47).withOpacity(0.06),
                onTap: () {
                  context.push(
                    '/topic-selection/${subject['id']}',
                    extra: subjectName,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: iconImageUrl != null
                              ? Image.network(
                                  iconImageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    emojiIcon,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                )
                              : Text(
                                  emojiIcon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // View 3: Exam Completion History View
  Widget _buildHistoryListView(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        final titles = [
          'ভেক্টর ও নিউটনীয় বলবিদ্যা প্র্যাকটিস কুইজ',
          'জৈব রসায়ন পরিচিতি শর্ট টেস্ট',
          'ম্যাট্রিক্স ও নির্ণায়ক অধ্যায় টেস্ট'
        ];
        final marks = ['স্কোর: ১৮/২০', 'স্কোর: ৭/১০', 'স্কোর: ২৫/২৫'];
        final dates = ['১৮ জুলাই, ২০২৬', '১৬ জুলাই, ২০২৬', '১০ জুলাই, ২০২৬'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              child: Icon(Icons.check, color: theme.colorScheme.primary),
            ),
            title: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(dates[index], style: const TextStyle(fontSize: 12)),
            ),
            trailing: Text(marks[index], style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ),
        );
      },
    );
  }

  // View 4: Student Progress Metrics with Graphs
  Widget _buildProgressView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Streaks multiplier card
          Card(
            color: const Color(0xFFFFF3E0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '৭ দিনের স্ট্রিক!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                      ),
                      Text(
                        'প্রতিদিন পরীক্ষা দিয়ে স্ট্রিক সচল রাখুন।',
                        style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // XP & Level stats card
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('মোট XP অর্জন', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          '১২৫০ XP',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('কারেন্ট লেভেল', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          'লেভেল ৫',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('সাপ্তাহিক কর্মদক্ষতা গ্রাফ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Performance Line Chart utilizing fl_chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 6.5),
                      FlSpot(5, 7.5),
                      FlSpot(6, 9),
                    ],
                    isCurved: true,
                    color: const Color(0xFF005C39),
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF005C39).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class LeaderboardPlayer {
  final String name;
  final int score;
  final String avatarText;
  final Color avatarBg;
  final bool isCurrentUser;

  LeaderboardPlayer({
    required this.name,
    required this.score,
    required this.avatarText,
    required this.avatarBg,
    this.isCurrentUser = false,
  });
}

class QuestionBankIcon extends StatelessWidget {
  final Color color;
  const QuestionBankIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 5,
            child: Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 2,
            child: FloatingWidget(
              child: Container(
                width: 14,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 8, height: 1.5, color: Colors.white),
                    Container(width: 6, height: 1.5, color: Colors.white),
                    Container(width: 4, height: 1.5, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickPracticeIcon extends StatelessWidget {
  final Color color;
  const QuickPracticeIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: PulseWidget(
              child: Icon(Icons.flash_on, size: 24, color: color),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 2,
            child: Container(width: 3, height: 3, decoration: BoxDecoration(color: color.withOpacity(0.5), shape: BoxShape.circle)),
          ),
          Positioned(
            top: 4,
            right: 2,
            child: Container(width: 2.5, height: 2.5, decoration: BoxDecoration(color: color.withOpacity(0.5), shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }
}

class MockExamIcon extends StatelessWidget {
  final Color color;
  const MockExamIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 4,
            child: Container(
              width: 15,
              height: 19,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 1,
            left: 8,
            child: Container(
              width: 7,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          Positioned(
            top: 7,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 7, height: 1.5, color: color),
                const SizedBox(height: 2),
                Container(width: 5, height: 1.5, color: color),
                const SizedBox(height: 2),
                Container(width: 7, height: 1.5, color: color),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: RotateWidget(
                  duration: const Duration(seconds: 4),
                  child: Transform.translate(
                    offset: const Offset(0, -1.5),
                    child: Container(
                      width: 1.2,
                      height: 3.5,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AIGuideIcon extends StatelessWidget {
  final Color color;
  const AIGuideIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotateWidget(
            duration: const Duration(seconds: 8),
            child: Stack(
              children: [
                Positioned(
                  top: 1,
                  left: 5,
                  child: Container(width: 3.5, height: 3.5, decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
                ),
                Positioned(
                  bottom: 2,
                  right: 5,
                  child: Container(width: 3.5, height: 3.5, decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
                ),
                Positioned(
                  top: 8,
                  right: 1,
                  child: Container(width: 2.5, height: 2.5, decoration: BoxDecoration(color: color.withOpacity(0.4), shape: BoxShape.circle)),
                ),
              ],
            ),
          ),
          PulseWidget(
            child: Icon(Icons.auto_awesome, size: 18, color: color),
          ),
        ],
      ),
    );
  }
}

// Micro-animation Loop Helper Widgets
class FloatingWidget extends StatefulWidget {
  final Widget child;
  const FloatingWidget({required this.child});

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget> {
  double _value = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _value),
      duration: const Duration(seconds: 1),
      onEnd: () {
        setState(() {
          _value = _value == 0.0 ? 3.0 : 0.0;
        });
      },
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class PulseWidget extends StatefulWidget {
  final Widget child;
  const PulseWidget({required this.child});

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: _scale),
      duration: const Duration(milliseconds: 900),
      onEnd: () {
        setState(() {
          _scale = _scale == 1.0 ? 1.15 : 1.0;
        });
      },
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class RotateWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const RotateWidget({required this.child, this.duration = const Duration(seconds: 4)});

  @override
  State<RotateWidget> createState() => _RotateWidgetState();
}

class _RotateWidgetState extends State<RotateWidget> {
  double _angle = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _angle),
      duration: widget.duration,
      onEnd: () {
        setState(() {
          _angle += 6.28318;
        });
      },
      builder: (context, angle, child) {
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class BannerSliderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  const BannerSliderWidget({super.key, required this.banners});

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _startAutoTimer();
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    if (widget.banners.length > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients && widget.banners.isNotEmpty) {
          final nextPage = (_currentIndex + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.banners.length,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                final String title = banner['title'] ?? '';
                final String badgeText = banner['badgeText'] ?? 'OFFER';
                final String? imageUrl = banner['imageUrl'];
                final String? rawTargetUrl = banner['targetUrl'];
                final bool isClickable = rawTargetUrl != null &&
                    rawTargetUrl.isNotEmpty &&
                    rawTargetUrl.trim() != '#' &&
                    rawTargetUrl.trim() != 'javascript:void(0)';
                final String targetUrl = isClickable ? rawTargetUrl.trim() : '';

                final List<Color> gradientColors = banner['colors'] ?? [const Color(0xFF004D40), const Color(0xFF00796B)];
                final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: GestureDetector(
                    onTap: isClickable
                        ? () {
                            if (targetUrl.startsWith('/')) {
                              context.push(targetUrl);
                            }
                          }
                        : null,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: !hasImage
                            ? LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        image: hasImage
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: hasImage
                          ? const SizedBox.expand()
                          : Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFD9746E), Color(0xFFF18881)],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: isClickable
                                              ? () {
                                                  if (targetUrl.startsWith('/')) {
                                                    context.push(targetUrl);
                                                  }
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            elevation: 0,
                                            minimumSize: const Size(0, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Get now',
                                            style: TextStyle(
                                              color: Color(0xFF004D40),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(banner['icon'] ?? '🦖', style: const TextStyle(fontSize: 38)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),

            // Sleek Floating Dots Overlay inside image
            if (widget.banners.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.banners.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


