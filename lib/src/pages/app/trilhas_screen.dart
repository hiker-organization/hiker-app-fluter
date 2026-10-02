import 'package:app_hiker/src/models/user_profile.dart';
import 'package:app_hiker/src/pages/app/trilhas/finish_trail_view.dart';
import 'package:app_hiker/src/pages/app/trilhas/trail_list_view.dart';
import 'package:app_hiker/src/pages/app/trilhas/trail_tracking_view.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/trail_tracker.dart';
import 'package:app_hiker/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// "Trilhas" tab. Shows the user's trails, the trail being tracked or the form to save a
// finished one, following the state of the TrailTracker so the footer stays visible.
class TrilhasScreen extends StatefulWidget {
  const TrilhasScreen({super.key});

  @override
  State<TrilhasScreen> createState() => _TrilhasScreenState();
}

class _TrilhasScreenState extends State<TrilhasScreen> {
  final _tracker = TrailTracker.instance;
  final _userService = UserService();

  UserProfile? _profile;
  // "Nova Trilha" was tapped but the trail hasn't started yet.
  bool _composing = false;
  // The user went back to the list while a trail is in progress.
  bool _showingList = false;
  int _listVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userService.getMe();
      if (mounted) setState(() => _profile = profile);
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } catch (_) {
      // The header shows placeholders; the trail features don't depend on it.
    }
  }

  void _backToList() {
    setState(() {
      _composing = false;
      _showingList = true;
    });
  }

  void _onTrailClosed() {
    setState(() {
      _composing = false;
      _showingList = false;
      _listVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _tracker,
        builder: (context, _) {
          final status = _tracker.status;

          if (status == TrailStatus.finished) {
            return FinishTrailView(profile: _profile, onClosed: _onTrailClosed);
          }

          final inProgress = status == TrailStatus.tracking || status == TrailStatus.paused;
          if ((inProgress && !_showingList) || (status == TrailStatus.idle && _composing)) {
            return TrailTrackingView(profile: _profile, onBack: _backToList);
          }

          return TrailListView(
            key: ValueKey(_listVersion),
            profile: _profile,
            onNewTrail: () => setState(() {
              _composing = true;
              _showingList = false;
            }),
          );
        },
      ),
    );
  }
}
