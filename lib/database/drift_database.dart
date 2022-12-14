// import -> private 값들은 불러올 수 없다.
import 'dart:io';

import 'package:calendar_scheduler/model/category_color.dart';
import 'package:calendar_scheduler/model/schedule.dart';
import 'package:calendar_scheduler/model/schedule_with_color.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// private 값까지 불러올 수 있다.
part 'drift_database.g.dart'; // import보다 넓은 기능

@DriftDatabase(
  tables: [
    // database 테이블로 인식 -> type선언 식
    Schedules,
    CategoryColors,
  ],
)
// 클래스 상속 받음 _$LocalDatabase -> drift가 만들어주는 클래스 -> drift_database.g.dart에 생성됨
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  Future<Schedule> getScheduleById(int id) =>
      (select(schedules)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<int> createSchedule(SchedulesCompanion data) =>
      into(schedules).insert(data); // id를 리턴받을 수 있음

  Future<int> createCategoryColor(CategoryColorsCompanion data) =>
      into(categoryColors).insert(data);

  Future<List<CategoryColor>> getCategoryColors() =>
      select(categoryColors).get(); // get() 모든 값 가져오기

  Future<int> updateScheduleById(int id, SchedulesCompanion data) =>
      (update(schedules)..where((tbl) => tbl.id.equals(id))).write(data);

  Future<int> removeSchedule(int id) =>
      (delete(schedules)..where((tbl) => tbl.id.equals(id))).go();

  Stream<List<ScheduleWithColor>> watchSchedules(DateTime date) {
    final query = select(schedules).join([
      innerJoin(categoryColors, categoryColors.id.equalsExp(schedules.colorId))
    ]);

    query.where(
      // 테이블 직접 명시
      schedules.date.equals(date),
    );
    query.orderBy(
      // asc -> ascending 오름차손
      // desc -> descing 내림차순
      [
        OrderingTerm.asc(schedules.startTime),
      ],
    );

    // rows : filtering 된 모든 값들
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ScheduleWithColor(
                  schedule: row.readTable(schedules),
                  categoryColor: row.readTable(categoryColors),
                ),
              )
              .toList(),
        );
  }

  @override
  int get schemaVersion => 1; // 테이블 상태의 버전
}

LazyDatabase _openConnection() {
  // database파일을 어떤 위치에 생성해 줄 건지 설정
  return LazyDatabase(() async {
    // 이 위치는 앱을 보통 설치하면 os에서 앱별 각각 사용 가능한 하드드라이브 특정위치를 지정해줌
    final dbFolder = await getApplicationDocumentsDirectory();
    final file =
        File(p.join(dbFolder.path, 'db.sqlite')); // database를 저장할 파일을 생성
    return NativeDatabase(file); // file로 데이터베이스 생성
  });
}
