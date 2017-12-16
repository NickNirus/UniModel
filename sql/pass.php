<?php
require 'vendor/autoload.php';

    $factory = new \RandomLib\Factory;
    $out1 = [
        'longine_v' => "",
        'makarov_m' => "",
        'zelenskiy_s' => "",
        'seny_a' => "",
        'tihonov_n' => "",
        'temnikov_s' => "",
        'voytovich_d' => "",
        'sorokina_s' => "",
        'chernova_m' => "",
        'dashevskiy_d' => "",
        'hohlov_m' => "",
        'alekseev_e' => "",
        'kilin_r' => "",
        'pogorelova_i' => "",
        'goncharov_a' => ""];
    $out2 = [
        'bondaryov_p' => "",
        'vyazovskaya_a' => "",
        'fedchenko_e' => "",
        'smirenko_k' => "",
        'yurchak_a' => "",
        ];
    $gen = $factory->getMediumStrengthGenerator();
    $id = 39906;
    $outstr = "";
    foreach ($out1 as $name => $pass) {
        $outstr .= 'UPDATE "public".users SET ("login", "password", "salt") = ';
        $salt = $gen->generateString(16);
        // $out1[$name] = sha1($salt."studentpass1").", ".$salt;
        $outstr .= "('".$name."', '".sha1($salt."studentpass1")."', '".$salt."') WHERE userid = ".$id++.";\n";
    }
    foreach ($out2 as $name => $pass) {
        $outstr .= 'UPDATE "public".users SET ("login", "password", "salt") = ';
        $salt = $gen->generateString(16);
        $out2[$name] = sha1($salt."profpass2").", ".$salt;
        $outstr .= "('".$name."', '".sha1($salt."profpass2")."', '".$salt."') WHERE userid = ".$id++.";\n";
    }
    echo $outstr;
?>
