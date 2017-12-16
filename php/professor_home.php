<?php
$professor = require_once("check_auth.php");
if($professor['professor'] != 't') {
    exit(json_encode(array(
        'noauth' => true
    )));
}
require_once ("DataBase.php");

if(isset($_GET['date'])) {
    $data = DataBase::instance()->get_timetable($professor['userid'], $_GET['date']);

    exit(json_encode($data, JSON_UNESCAPED_UNICODE));    
}

$data = [
    'person' => DataBase::instance()->get_personal_professor_info($professor['userid']),
    'subjects' => DataBase::instance()->get_subjects($professor['userid']),
    'timetable' => DataBase::instance()->get_timetable($professor['userid']),
];
exit(json_encode($data, JSON_UNESCAPED_UNICODE));

?>