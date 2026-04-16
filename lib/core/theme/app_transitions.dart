import 'package:flutter/cupertino.dart';

class AppTransitions {
  static const _duration = Duration(milliseconds: 460);
  static const _curve = Curves.easeInOutCubic;

  static Route<T> fadeSlide<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = _duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: _curve);
        final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
        return FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.025, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> slideFromRight<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = _duration,
  }) {
    return CupertinoPageRoute<T>(
      settings: settings,
      builder: (context) => page,
    );
  }

  static PageTransitionsBuilder get fadeSlideBuilder =>
      const _FadeSlidePageTransitionsBuilder();

  static Widget goRouterFadeSlide(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: _curve);
    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    return FadeTransition(
      opacity: fadeIn,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.025, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double>? secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppTransitions._curve);
    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    return FadeTransition(
      opacity: fadeIn,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.025, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
