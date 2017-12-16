<?php
$professor = require_once("check_auth.php");
if($professor['professor'] != 't') {
    exit(json_encode(array(
        'noauth' => true
    )));
}
require_once ("DataBase.php");

// get list
if(isset($_GET['subject_id'])) {
    $data = [
        'marks' => DataBase::instance()->get_professor_marks($professor['userid'], $_GET['subject_id']),
        'students' => DataBase::instance()->get_autocomplete_students($_GET['subject_id']),
        'timetable_id' => $_GET['timetable_id']
    ];

    exit(json_encode($data, JSON_UNESCAPED_UNICODE));    
}

if(isset($_POST['add_mark'])) {
    // insert
    $status = DataBase::instance()->insert_mark($professor['userid'], json_decode($_POST['add_mark'], true));
}

if(isset($_POST['edit_mark_id'])) {
    // update
    $status = DataBase::instance()->update_mark($_POST['mark_id'], $_POST['mark_value'], $professor['userid']);
}

?>