import 'package:calendar_scheduler/const/colors.dart';
import 'package:calendar_scheduler/component/custom_text_field.dart';
import 'package:calendar_scheduler/database/drift_database.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ScheduleBottomSheet extends StatefulWidget {
  final DateTime selectedDate;

  const ScheduleBottomSheet({
    required this.selectedDate,
    Key? key,
  }) : super(key: key);

  @override
  State<ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<ScheduleBottomSheet> {
  final GlobalKey<FormState> formKey = GlobalKey();

  int? startTime;
  int? endTime;
  String? content;
  int? selectedColorId;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height / 2 + bottomInset,
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 8.0, right: 8.0, top: 16.0, bottom: 0),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.always,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Time(
                      onStartSaved: (String? val) {
                        startTime = int.parse(
                            val!); // validator에서 이미 분류하기 때문에 null값을 넣을 수 없음
                      },
                      onEndSaved: (String? val) {
                        endTime = int.parse(val!);
                      },
                    ),
                    SizedBox(height: 16.0),
                    _Content(
                      onSaved: (String? val) {
                        content = val;
                      },
                    ),
                    SizedBox(height: 16.0),
                    FutureBuilder<List<CategoryColor>>(
                        future: GetIt.I<LocalDatabase>().getCategoryColors(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              selectedColorId == null &&
                              snapshot.data!.isNotEmpty) {
                            selectedColorId = snapshot.data![0].id;
                          }
                          return _ColorPicker(
                            colors: snapshot.hasData ? snapshot.data! : [],
                            selectedId: selectedColorId,
                            colorIdSetter: (int id) {
                              selectedColorId = id;
                            },
                          );
                        }),
                    SizedBox(height: 8.0),
                    _SaveButton(
                      onPressed: onSavePressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onSavePressed() {
    // formKey는 생성을 했는데
    // Form 위젯과 결합을 안했을 때
    if (formKey.currentState == null) {
      return;
    }
    // Form 내 모든 TextFormField의 validator 함수가 한번에 실행됨
    if (formKey.currentState!.validate()) {
      // null값 리턴 시 -> 에러가 없을 때 true가 된다.
      formKey.currentState!.save();

      print('----------------------');
      print('StartTime : $startTime');
      print('EndTime : $endTime');
      print('Content : $content');
    } else {
      // 어떤 TextField 하나라도 String값이 리턴되 에러가 있다고 인식 -> false
      print('에러가 있습니다');
    }
  }
}

class _Time extends StatelessWidget {
  final FormFieldSetter<String> onStartSaved;
  final FormFieldSetter<String> onEndSaved;

  const _Time({
    required this.onStartSaved,
    required this.onEndSaved,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            label: '시작 시간',
            isTime: true,
            onSaved: onStartSaved,
          ),
        ),
        SizedBox(
          width: 16.0,
        ),
        Expanded(
          child: CustomTextField(
            label: '마감 시간',
            isTime: true,
            onSaved: onEndSaved,
          ),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  final FormFieldSetter<String> onSaved;

  const _Content({
    required this.onSaved,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CustomTextField(
        label: '내용',
        isTime: false,
        onSaved: onSaved,
      ),
    );
  }
}

typedef ColorIdSetter = void Function(int id);

class _ColorPicker extends StatelessWidget {
  final List<CategoryColor> colors;
  final int? selectedId;
  final ColorIdSetter colorIdSetter;

  const _ColorPicker({
    required this.colors,
    required this.selectedId,
    required this.colorIdSetter,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 10.0,
      children: colors
          .map(
            (e) => GestureDetector(
              onTap: () {
                colorIdSetter(e.id);
              },
              child: renderColor(
                e,
                selectedId == e.id,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget renderColor(CategoryColor color, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(
          int.parse(
            'FF${color.hexCode}',
            radix: 16,
          ),
        ),
        border: isSelected
            ? Border.all(
                color: Colors.black,
                width: 4.0,
              )
            : null,
      ),
      width: 32.0,
      height: 32.0,
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SaveButton({
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              primary: PRIMARY_COLOR,
            ),
            child: Text('저장'),
          ),
        ),
      ],
    );
  }
}
