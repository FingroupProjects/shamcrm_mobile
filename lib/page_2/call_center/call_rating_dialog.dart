import 'package:crm_task_manager/bloc/call_bloc/call_center_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_event.dart';
import 'package:crm_task_manager/custom_widget/custom_textf.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CallRatingDialog extends StatefulWidget {
  final String? initialRating;
  final String? initialComment;
  final int callId;
  final int organizationId;
  final Function(String?, String?) onSubmit;

  const CallRatingDialog({
    Key? key,
    this.initialRating,
    this.initialComment,
    required this.callId,
    required this.organizationId,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _CallRatingDialogState createState() => _CallRatingDialogState();
}

class _CallRatingDialogState extends State<CallRatingDialog> {
  final TextEditingController _commentController = TextEditingController();
  String? _selectedRating;
  bool _hasValidationError = false;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
    _commentController.text = widget.initialComment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        int starNumber = index + 1;
        bool isSelected = _selectedRating != null &&
            int.parse(_selectedRating!) >= starNumber;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = starNumber.toString();
              if (_hasValidationError) {
                _hasValidationError = false;
                _errorText = null;
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset(
              isSelected
                  ? 'assets/icons/AppBar/star_on.png'
                  : 'assets/icons/AppBar/star_off.png',
              width: 36,
              height: 36,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
          minWidth: 280,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('rate_call'),
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.translate('rating_stars'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStarRating(),
                const SizedBox(height: 4),
                if (_hasValidationError && _errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  child: CustomTextFieldNoLabel(
                    controller: _commentController,
                    hintText: AppLocalizations.of(context)!.translate('write_comment'),
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) {
                      if (_hasValidationError) {
                        setState(() {
                          _hasValidationError = false;
                          _errorText = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: Text(
                          AppLocalizations.of(context)!.translate('cancel'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xff1E2E52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_selectedRating == null) {
                                  setState(() {
                                    _hasValidationError = true;
                                    _errorText = AppLocalizations.of(context)!
                                        .translate('field_required');
                                  });
                                  return;
                                }

                                setState(() {
                                  _isSubmitting = true;
                                });

                                // Отправляем событие в BLoC
                                context.read<CallCenterBloc>().add(
                                      SubmitCallRatingAndReport(
                                        callId: widget.callId,
                                        rating: int.parse(_selectedRating!),
                                        report: _commentController.text,
                                        organizationId: widget.organizationId,
                                      ),
                                    );

                                // Локальное обновление UI
                                widget.onSubmit(
                                    _selectedRating, _commentController.text);

                                Navigator.of(context).pop();
                              },
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.translate('confirm'),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}