<?php
require 'vendor/autoload.php';
require_once 'DataBase.php';

if(!(isset($_POST['login']) && isset($_POST['password']))) {
    return false;
} else {
    $login = $_POST['login'];
    $password = $_POST['password'];
    $user = DataBase::instance()->get_user_data($login);
    if(!$user || count($user) == 0) {
        exit(json_encode(array('error'=>"Auth failed, check your login or password.")));
    } else {
        if($user['password'] == (sha1($user['salt'].$password))) {
            // make token and write to base
            $factory = new \RandomLib\Factory;
            $gen = $factory->getMediumStrengthGenerator();
            $token = $gen->generateString(32);
            DataBase::instance()->update_user_token($user['userid'], $token);
            // drop old cookies if they exist
            setcookie('unimodel_student_token', null, -1);
            setcookie('unimodel_professor_token', null, -1);        
            // and make new ones
            if($user['professor'] == 'f') {
                setcookie("unimodel_student_token", $token, time() + 60*60*24*30);
                $redirect = "student_home.html";
            } else {
                setcookie("unimodel_professor_token", $token, time() + 60*60*24*30);
                $redirect = "professor_home.html";
            }
            // done
            // header('Location: '.$_SERVER['REMOTE_ADDR'].'/catalog.html');
            exit(json_encode(['success' => true, 'redirect' => $redirect]));
        }
    }
    exit(json_encode(['error'=>"Authorization failed, check your login or password."]));
}
?>