<?php
$student = require_once("check_auth.php");
if($student['professor'] != 'f') {
    exit(json_encode(array(
        'noauth' => true
    )));
}
require_once ("DataBase.php");

if(isset($_GET['date'])) {
    $data = DataBase::instance()->get_timetable($student['userid'], $_GET['date']);

    exit(json_encode($data, JSON_UNESCAPED_UNICODE));    
}

$data = [
    'person' => DataBase::instance()->get_personal_student_info($student['userid']),
    'subjects' => DataBase::instance()->get_subjects($student['userid']),
    'timetable' => DataBase::instance()->get_timetable($student['userid']),
    'marks' => DataBase::instance()->get_student_marks($student['userid'])
];
exit(json_encode($data, JSON_UNESCAPED_UNICODE));

?>