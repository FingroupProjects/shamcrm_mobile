import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_event.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_state.dart';
import 'package:crm_task_manager/models/page_2/call_center_by_id_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/page_2/call_center/call_rating_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/main.dart';

class PlaybackSpeed {
  final double speed;
  final String name;

  PlaybackSpeed({required this.speed, required this.name});

  @override
  String toString() => name;
}

class CallDetailsScreen extends StatefulWidget {
  final CallLogEntry callEntry;

  const CallDetailsScreen({Key? key, required this.callEntry}) : super(key: key);

  @override
  _CallDetailsScreenState createState() => _CallDetailsScreenState();
}

class _CallDetailsScreenState extends State<CallDetailsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _selectedRating;
  String? _ratingComment;
  double _selectedSpeed = 1.0;

  final List<PlaybackSpeed> _playbackSpeeds = [
    PlaybackSpeed(speed: 0.5, name: '0.5x'),
    PlaybackSpeed(speed: 1.0, name: '1.0x'),
    PlaybackSpeed(speed: 1.5, name: '1.5x'),
    PlaybackSpeed(speed: 2.0, name: '2.0x'),
  ];

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    context.read<CallCenterBloc>().add(LoadCallById(callId: int.parse(widget.callEntry.id)));
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

String formatDate(DateTime? date) {
  //print('Input date: $date, isUtc: ${date?.isUtc}');
  if (date == null) {
    return AppLocalizations.of(context)!.translate('date_unknown') ?? 'Дата неизвестна';
  }

  try {
    final utcDate = DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );
    final localDate = utcDate.toLocal();
    //print('UTC date: $utcDate, Local date: $localDate');
    return DateFormat('dd.MM.yy HH:mm').format(localDate);
  } catch (e) {
    //print('Error formatting date: $e');
    return AppLocalizations.of(context)!.translate('invalid_format') ?? 'Неверный формат даты';
  }
}
  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showRatingDialog() {
    showDialog(

      context: context,
      builder: (BuildContext context) {
        return CallRatingDialog(
          initialRating: _selectedRating,
          initialComment: _ratingComment,
          callId: int.parse(widget.callEntry.id),
          organizationId: 1, // TODO: Replace with actual organizationId
          onSubmit: (rating, comment) {
            setState(() {
              _selectedRating = rating;
              _ratingComment = comment;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, AppLocalizations.of(context)!.translate('call_details')),
      backgroundColor: Colors.white,
      body: BlocListener<CallCenterBloc, CallCenterState>(
        listener: (context, state) {
          if (state is CallCenterError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is CallByIdLoaded) {
            // Update state in listener instead of builder
            setState(() {
              _selectedRating = state.call.rating?.toString();
              _ratingComment = state.call.report;
            });
          }
        },
        child: BlocBuilder<CallCenterBloc, CallCenterState>(
          builder: (context, state) {
            if (state is CallCenterLoading) {
              return _buildLoadingState();
            } else if (state is CallByIdLoaded) {
              return _buildDetailsList(state.call);
            } else if (state is CallCenterError) {
              return _buildDetailsListFromEntry(widget.callEntry);
            }
            return _buildDetailsListFromEntry(widget.callEntry);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2E52),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildDetailsList(CallById call) {
  // Формируем список деталей, исключая "Оценка" и "Комментарий" для пропущенных звонков
  final details = <Map<String, dynamic>>[
    {
      'label': AppLocalizations.of(context)!.translate('lead_name') as String,
      'value': call.lead.name as String,
    },
    {
      'label': AppLocalizations.of(context)!.translate('phone_number') as String,
      'value': call.lead.phone as String,
    },
    {
      'label': AppLocalizations.of(context)!.translate('date_of_call') as String,
      'value': formatDate(call.callStartedAt) as String,
    },
    {
      'label': AppLocalizations.of(context)!.translate('operator') as String,
      'value': call.user?.fullName ?? AppLocalizations.of(context)!.translate('not_specified'),
    },
    {
      'label': AppLocalizations.of(context)!.translate('call_type') as String,
      'value': _getCallTypeText(call.incoming, call.missed) as String,
    },
    {
      'label': AppLocalizations.of(context)!.translate('call_duration_title') as String,
      'value': call.callDuration != null
          ? _formatDuration(Duration(seconds: call.callDuration!))
          : AppLocalizations.of(context)!.translate('not_available'),
    },
    // Добавляем "Оценка" и "Комментарий" только если звонок НЕ пропущен
    if (!call.missed) ...[
      {
        'label': AppLocalizations.of(context)!.translate('rating') as String,
        'value': call.rating?.toString() ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('comment') as String,
        'value': call.report ?? '',
      },
    ],
    {
      'label': 'call_details' as String,
      'value': '' as String,
      'call_data': <String, String>{
        'caller': call.lead.name,
        'call_duration': call.callDuration != null
            ? _formatDuration(Duration(seconds: call.callDuration!))
            : AppLocalizations.of(context)!.translate('not_available'),
        'call_type': _getCallTypeText(call.incoming, call.missed),
      },
    },
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: details.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildDetailItem(
                    details[index]['label'] as String,
                    details[index]['value'] as String,
                    call,
                    index,
                    callData: details[index]['call_data'] as Map<String, String>?,
                  ),
                );
              },
            ),
            // Отображаем кнопку "Оценить" только если звонок НЕ пропущен
            if (!call.missed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF1E2E52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _showRatingDialog,
                  child: Text(
                    AppLocalizations.of(context)!.translate('grade'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

 Widget _buildDetailsListFromEntry(CallLogEntry call) {
  // Формируем список деталей, исключая "Оценка" и "Комментарий" для пропущенных звонков
  final details = <Map<String, dynamic>>[
    {
      'label': AppLocalizations.of(context)!.translate('lead_name') as String,
      'value': call.leadName as String,
    },
    {
      'label': AppLocalizations.of(context)!.translate('phone_number') as String,
      'value': call.phoneNumber as String,
    },
    {
      'label': AppLocalizations.of(context)!.translate('date_of_call') as String,
      'value': formatDate(call.callDate) as String,
    },
    {
      'label': AppLocalizations.of(context)!.translate('operator') as String,
      'value': call.operatorName ?? AppLocalizations.of(context)!.translate('not_specified'),
    },
    {
      'label': AppLocalizations.of(context)!.translate('call_type') as String,
      'value': _getCallTypeTextFromEntry(call.callType) as String,
    },
    {
      'label': AppLocalizations.of(context)!.translate('call_duration_title') as String,
      'value': _formatDuration(call.duration) as String,
    },
    // Добавляем "Оценка" и "Комментарий" только если звонок НЕ пропущен
    if (call.callType != CallType.missed) ...[
      {
        'label': AppLocalizations.of(context)!.translate('rating') as String,
        'value': call.rating ?? _selectedRating ?? AppLocalizations.of(context)!.translate(''),
      },
      {
        'label': AppLocalizations.of(context)!.translate('comment') as String,
        'value': call.report ?? _ratingComment ?? AppLocalizations.of(context)!.translate(''),
      },
    ],
    {
      'label': 'call_details' as String,
      'value': '' as String,
      'call_data': <String, String>{
        'caller': call.leadName,
        'call_duration': _formatDuration(call.duration),
        'call_type': _getCallTypeTextFromEntry(call.callType),
      },
    },
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: details.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildDetailItemFromEntry(
                    details[index]['label'] as String,
                    details[index]['value'] as String,
                    call,
                    index,
                    callData: details[index]['call_data'] as Map<String, String>?,
                  ),
                );
              },
            ),
            // Отображаем кнопку "Оценить" только если звонок НЕ пропущен
            if (call.callType != CallType.missed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF1E2E52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _showRatingDialog,
                  child: Text(
                    AppLocalizations.of(context)!.translate('grade'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

  String _getCallTypeText(bool incoming, bool missed) {
    if (missed) {
      return AppLocalizations.of(context)!.translate('missed_call');
    } else if (incoming) {
      return AppLocalizations.of(context)!.translate('incoming_call');
    } else {
      return AppLocalizations.of(context)!.translate('outgoing_call');
    }
  }

  String _getCallTypeTextFromEntry(CallType callType) {
    switch (callType) {
      case CallType.incoming:
        return AppLocalizations.of(context)!.translate('incoming_call');
      case CallType.outgoing:
        return AppLocalizations.of(context)!.translate('outgoing_call');
      case CallType.missed:
        return AppLocalizations.of(context)!.translate('missed_call');
    }
  }

  Widget _buildDetailItem(
    String label,
    String value,
    CallById call,
    int index, {
    Map<String, String>? callData,
  }) {
    if (label == AppLocalizations.of(context)!.translate('rating') ||
        label == AppLocalizations.of(context)!.translate('comment')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(label),
              const SizedBox(width: 8),
              Expanded(
                child: _buildValue(value.isNotEmpty ? value : AppLocalizations.of(context)!.translate('')),
              ),
            ],
          ),
        ],
      );
    }

    if (label == 'call_details') {
      bool isMissed = call.missed;
      bool isIncoming = call.incoming;
      Color statusColor = isMissed ? const Color(0xffFEE6E6) : const Color(0xffE6F4EA);
      String statusText = _getCallTypeText(call.incoming, call.missed);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xff1E2E52),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.translate('lead_deal_card'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
                Expanded(
                  child: Text(
                    callData!['caller']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xff1E2E52),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.translate('call_duration_title') + ' ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
                Text(
                  callData!['call_duration']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: isMissed ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: isMissed ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.translate('call_recording'),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xff99A4BA),
              ),
            ),
            if (call.callDuration != null && call.callDuration! > 0 && !call.missed) ...[
              const SizedBox(height: 0),
              _buildVoicePlayer(call.callRecordUrl, call.callDuration!),
            ],
          ],
        ),
      );
    }

    if (label == AppLocalizations.of(context)!.translate('lead_name')) {
      return GestureDetector(
        onTap: () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => LeadDetailsScreen(
                leadId: call.lead.id.toString(),
                leadName: call.lead.name,
                leadStatus: "",
                statusId: 1,
              ),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(width: 8),
        Expanded(
          child: _buildValue(value),
        ),
      ],
    );
  }

  Widget _buildDetailItemFromEntry(
    String label,
    String value,
    CallLogEntry call,
    int index, {
    Map<String, String>? callData,
  }) {
    if (label == AppLocalizations.of(context)!.translate('rating') ||
        label == AppLocalizations.of(context)!.translate('comment')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(label),
              const SizedBox(width: 8),
              Expanded(
                child: _buildValue(value.isNotEmpty ? value : AppLocalizations.of(context)!.translate('')),
              ),
            ],
          ),
        ],
      );
    }

    if (label == 'call_details') {
      bool isMissed = call.callType == CallType.missed;
      bool isIncoming = call.callType == CallType.incoming;
      Color statusColor = isMissed ? const Color(0xffFEE6E6) : const Color(0xffE6F4EA);
      String statusText = _getCallTypeTextFromEntry(call.callType);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xff1E2E52),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.translate('lead_deal_card'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
                Expanded(
                  child: Text(
                    callData!['caller']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xff1E2E52),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.translate('call_duration_title') + ' ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
                Text(
                  callData!['call_duration']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: isMissed ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: isMissed ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.translate('call_recording'),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xff99A4BA),
              ),
            ),
            if (call.duration != null && call.callType != CallType.missed) ...[
              const SizedBox(height: 0),
              _buildVoicePlayer('assets/audio/voice_operator.mp3', call.duration!.inSeconds),
            ],
          ],
        ),
      );
    }

    if (label == AppLocalizations.of(context)!.translate('lead_name')) {
      return GestureDetector(
        onTap: () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => LeadDetailsScreen(
                leadId: call.id,
                leadName: call.leadName,
                leadStatus: "",
                statusId: 1,
              ),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(width: 8),
        Expanded(
          child: _buildValue(value),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
    );
  }

  Widget _buildVoicePlayer(String recordPath, int callDuration) {
    final assetPath = recordPath.startsWith('assets/') ? recordPath.substring(7) : recordPath;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    //print('Attempting to play audio from: $assetPath');
                    if (_isPlaying) {
                      //print('Pausing audio');
                      await _audioPlayer.pause();
                      setState(() {
                        _isPlaying = false;
                      });
                    } else {
                      //print('Setting audio source');
                      await _audioPlayer.setSourceUrl(assetPath);
                      //print('Resuming audio');
                      await _audioPlayer.resume();
                      setState(() {
                        _isPlaying = true;
                      });
                    }
                  } catch (e, stackTrace) {
                    //print('Audio playback error: $e\nStackTrace: $stackTrace');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.translate('audio_playback_error'),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDuration(_position),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff1E2E52),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _position.inSeconds.toDouble(),
                  min: 0.0,
                  max: _duration.inSeconds > 0
                      ? _duration.inSeconds.toDouble()
                      : callDuration.toDouble(),
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey[300],
                  onChanged: (value) async {
                    final newPosition = Duration(seconds: value.toInt());
                    try {
                      await _audioPlayer.seek(newPosition);
                      setState(() {
                        _position = newPosition;
                      });
                    } catch (e) {
                      //print('Audio seek error: $e');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(Duration(seconds: callDuration)),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff1E2E52),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  int currentIndex = _playbackSpeeds.indexWhere(
                    (speed) => speed.speed == _selectedSpeed,
                  );
                  int nextIndex = (currentIndex + 1) % _playbackSpeeds.length;
                  PlaybackSpeed newSpeed = _playbackSpeeds[nextIndex];

                  setState(() {
                    _selectedSpeed = newSpeed.speed;
                  });

                  try {
                    await _audioPlayer.setPlaybackRate(newSpeed.speed);
                  } catch (e) {
                    //print('Error setting playback rate: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.translate('playback_speed_error'),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedSpeed}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}