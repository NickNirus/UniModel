<?php
if(!(isset($_COOKIE['unimodel_student_token']) || isset($_COOKIE['unimodel_professor_token']) )) {
    return -1;
} else {
    require_once('DataBase.php');
    if(isset($_COOKIE['unimodel_student_token'])) {
        $cookie_token = $_COOKIE['unimodel_student_token'];
    } elseif (isset($_COOKIE['unimodel_professor_token'])) {
        $cookie_token = $_COOKIE['unimodel_professor_token'];
    }
    $user = DataBase::instance()->get_user_by_token($cookie_token);
    if(!($user) || count($user) == 0) {
        return -1;
    } else {
        return $user;
    }
}
?>