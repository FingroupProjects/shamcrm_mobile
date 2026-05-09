import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_add_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sip_service.dart';
import 'sip_state.dart';

part 'models/sip_contact_models.dart';
part 'logic/sip_screen_call_state.dart';
part 'logic/sip_screen_contacts.dart';
part 'logic/sip_screen_dialer.dart';
part 'logic/sip_screen_search.dart';
part 'widgets/sip_call_views.dart';
part 'widgets/sip_glass_widgets.dart';
part 'widgets/sip_main_views.dart';
part 'widgets/sip_settings_sheet.dart';

class SipScreen extends StatefulWidget {
  const SipScreen({super.key});

  @override
  State<SipScreen> createState() => _SipScreenState();
}

class _SipScreenState extends State<SipScreen>
    with SingleTickerProviderStateMixin {
  static final SipService _sipService = SipService();

  SipService get _sipRuntime => _sipService;
  final ApiService _apiService = ApiService();

  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _sipIdController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final FocusNode _dialFocusNode = FocusNode();
  final AudioPlayer _callFeedbackPlayer = AudioPlayer();

  SipTransportUi _selectedTransport = SipTransportUi.ws;

  int _bottomTabIndex = 0;
  late final AnimationController _pulseController;
  Timer? _callDurationTimer;
  SipCallUiStatus? _lastObservedCallStatus;
  String? _activeFeedbackAsset;
  DateTime? _connectedAt;
  Duration _connectedDuration = Duration.zero;
  bool _contactsEnabled = false;
  bool _contactsLoaded = false;
  bool _contactsPermissionDenied = false;
  List<Contact> _contacts = const [];
  List<_SipIndexedContact> _indexedContacts = const [];
  List<_SipContactSuggestion> _contactSuggestions = const [];
  bool _showInCallKeypad = false;
  String _inCallDigits = '';
  double _incomingAnswerDrag = 0;
  Timer? _contactSearchDebounce;
  Timer? _draftSaveDebounce;
  bool _suspendDraftAutosave = false;
  bool _isDialPanelCollapsed = false;
  String _contactsViewQuery = '';
  String _searchViewQuery = '';
  double? _liquidNavDragIndex;
  bool _isLiquidNavPressed = false;
  bool _leadSearchEnabled = false;
  bool _isLeadSearchLoading = false;
  List<Lead> _searchLeadResults = const [];
  Timer? _leadSearchDebounce;
  int _leadSearchRequestId = 0;
  _SipSearchSource _searchSource = _SipSearchSource.calls;

  static const List<Map<String, String>> _dialPadItems = [
    {'key': '1', 'letters': ''},
    {'key': '2', 'letters': 'АБВГ\nABC'},
    {'key': '3', 'letters': 'ДЕЖЗ\nDEF'},
    {'key': '4', 'letters': 'ИЙКЛ\nGHI'},
    {'key': '5', 'letters': 'МНОП\nJKL'},
    {'key': '6', 'letters': 'РСТУ\nMNO'},
    {'key': '7', 'letters': 'ФХЦЧ\nPQRS'},
    {'key': '8', 'letters': 'ШЩЪЫ\nTUV'},
    {'key': '9', 'letters': 'ЬЭЮЯ\nWXYZ'},
    {'key': '*', 'letters': ''},
    {'key': '0', 'letters': '+'},
    {'key': '#', 'letters': ''},
  ];

  void _updateView(VoidCallback action) {
    if (!mounted) return;
    setState(action);
  }

  void _expandDialPanel() {
    if (!_isDialPanelCollapsed) return;
    _updateView(() {
      _isDialPanelCollapsed = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _sipService.setSipScreenVisible(true);
    _serverController.addListener(_handleDraftChanged);
    _loginController.addListener(_handleDraftChanged);
    _passwordController.addListener(_handleDraftChanged);
    _portController.addListener(_handleDraftChanged);
    _sipIdController.addListener(_handleDialChanged);
    _sipIdController.addListener(_handleDraftChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _configureCallFeedbackPlayer();
    _initializeSip();
  }

  Future<void> _configureCallFeedbackPlayer() async {
    try {
      await _callFeedbackPlayer.setReleaseMode(ReleaseMode.loop);
      await _callFeedbackPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _callFeedbackPlayer.setVolume(1);
    } catch (_) {}
  }

  Future<void> _initializeSip() async {
    await _sipService.initialize();
    await _sipService.prepareSipRuntimePermissions();
    await _loadContactsConfiguration();
    await _loadSearchCapabilities();
    final state = _sipService.state;

    _suspendDraftAutosave = true;
    _serverController.text = state.server;
    _loginController.text = state.login;
    _passwordController.text = state.password;
    _sipIdController.text = state.sipId;
    _portController.text = state.port.toString();
    _selectedTransport = state.transport;
    _suspendDraftAutosave = false;

    if (mounted) {
      _refreshContactSuggestions();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _sipService.setSipScreenVisible(false);
    _callDurationTimer?.cancel();
    _contactSearchDebounce?.cancel();
    _draftSaveDebounce?.cancel();
    _leadSearchDebounce?.cancel();
    _pulseController.dispose();
    unawaited(_callFeedbackPlayer.stop());
    _callFeedbackPlayer.dispose();
    _sipIdController.removeListener(_handleDialChanged);
    _serverController.removeListener(_handleDraftChanged);
    _loginController.removeListener(_handleDraftChanged);
    _passwordController.removeListener(_handleDraftChanged);
    _portController.removeListener(_handleDraftChanged);
    _sipIdController.removeListener(_handleDraftChanged);
    _serverController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _sipIdController.dispose();
    _portController.dispose();
    _dialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sipService,
      builder: (context, child) {
        if (!_sipService.isConfigLoaded) {
          return const Scaffold(
            backgroundColor: _G.lightBg,
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final state = _sipService.state;
        final isActiveCall = _isActiveCallState(state.callStatus);

        _syncCallEffects(state);

        if (!_hasCredentials(state)) {
          return _buildAuthorizationView(context, state);
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: _G.lightBg,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEFF4FF), Color(0xFFF8FAFF)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: isActiveCall
                      ? _activeCallView(context, state)
                      : Column(
                          children: [
                            _buildTopBar(context, state),
                            if (state.callStatus == SipCallUiStatus.incoming ||
                                state.registrationStatus !=
                                    SipRegistrationUiStatus.registered)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _statusBanner(context, state),
                              ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: switch (_bottomTabIndex) {
                                  0 => _dialPadView(context, state),
                                  2 => _contactsView(context),
                                  3 => _searchView(context, state),
                                  _ => _journalView(context, state),
                                },
                              ),
                            ),
                            if (_bottomTabIndex != 0) _bottomSwitcher(context),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
