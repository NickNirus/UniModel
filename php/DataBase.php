<?php
define("_schema_name", "rusin_n_408_db");
    
// Trying out singletons, because why not.
class DataBase
{
    private static $_instance = null;
    private $db;
    private $token_query;
    private $subject_students_query;

    // public function __construct()
    private function __construct()
    {
        $this->db = pg_connect("host=localhost port=5432 dbname=UniTest user=rusin_n_408_db_unimodel_user password=cbuvfEybdthcbntn1 options='--client_encoding=UTF8'");
        if(!$this->db){
            return json_encode(['error' => pg_last_error()]);
        }
        // cache this, because it's used in literally every page call
        $this->token_query = pg_prepare($this->db, "token_query", 'SELECT userid, professor FROM '._schema_name.'.users WHERE token = $1;');
        // and this, because it has to be heckin fast
        $this->subject_students_query = pg_prepare($this->db, "subject_students_query", 
            'SELECT s."userid", s."name", s."surname", s."patronymic" 
            FROM '._schema_name.'.students s 
            JOIN '._schema_name.'.subject_participation sp 
            ON sp."userid" = s."userid" 
            WHERE sp."subject" = $1;');
    }
    // Singleton specs
    // stops object cloning
    protected function __clone(){
    }

    // instantiator
    public static function instance() {
        if(is_null(self::$_instance)) {
            self::$_instance = new self();
        }
        return self::$_instance;
    }

    // Technical functions

    public function get_autocomplete_students($subject_id) {
        $students = pg_execute($this->db, "subject_students_query", [$subject_id]);
        if($students == false) {
            return ['error' => pg_last_error()];
        }
        return pg_fetch_all($students);
    }
    
    public function update_user_token($user_id, $token) {
        $update_token = pg_query($this->db, 'UPDATE '._schema_name.'.users SET token = '.pg_escape_literal($token).' WHERE userid = '.pg_escape_literal($user_id).';');
        if($update_token == false) {
            return ['error' => pg_last_error()];
        }
    }

    public function get_user_by_token($token) {
        $get_user = pg_execute($this->db, "token_query", [$token]);
        if($get_user == false) {
            return ['error' => pg_last_error()];
        }
        return pg_fetch_assoc($get_user);
    }

    /* 
    Student:
        no insert
        select timetable, subj-participation and avg-mark - all in one
    Professor:
        select timetable, subj-participation - on screen A
        select marks on subject sorted by date - on screen B
        insert/update marks - from screen B
    Admin:
        man, fuck all that work tho    
    */

    public function get_user_data($user_id) {
        $query = 'SELECT * FROM '._schema_name.'.auth WHERE "login" = '.pg_escape_literal($user_id);
        $result = pg_query($this->db, $query);
        if (!$result) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_assoc($result);        
    }

    public function get_timetable($user_id, $date = null) {
        if($date == null) {
            $date = date("Y-m-d");
        }
        $timetable_query = 
            'SELECT s."id" subject_id, s."name" subject_name, s."type" subject_type, tt."id" timetable_id, tt."date" FROM '._schema_name.'.subject_participation sp 
                JOIN '._schema_name.'.subjects s 
                ON s."id" = sp.subject
                JOIN '._schema_name.'.timetable tt 
                ON sp.subject = tt.subject
                WHERE sp.userid = '.pg_escape_literal($user_id).' AND tt."date" = \''.pg_escape_string($date).'\'
                ORDER BY tt."id";';
        $query = pg_query($this->db, $timetable_query);
        if (!$query) {
            return json_encode(['error' => pg_last_error()]);
        }
        // return pg_fetch_assoc($query);
        return pg_fetch_all($query);
    }

    public function get_subjects($user_id) {
        $subjects_query = 
            'SELECT s."id", s."name", s."type" FROM '._schema_name.'.subjects s 
                JOIN '._schema_name.'.subject_participation sp
                ON sp.subject = s."id"
                WHERE sp.userid = '.pg_escape_literal($user_id).';';
        $query = pg_query($this->db, $subjects_query);
        if (!$query) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_all($query);
    }

    public function get_subject($sbj_id) {
        $subject_query = 
            'SELECT s."name", s."type" FROM '._schema_name.'.subjects s
            WHERE s."id" = '.pg_escape_literal($sbj_id).';';
        $query = pg_query($this->db, $subject_query);
        if (!$query) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_assoc($query);
    }

    public function get_personal_student_info($student_id) {
        $query = 'SELECT * FROM '._schema_name.'.students WHERE userid = '.pg_escape_literal($student_id);
        $result = pg_query($this->db, $query);
        if (!$result) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_assoc($result);
    }

    public function get_student_marks($student_id) {
        $marks_query = 
            'SELECT mks."value" mark, u."name" prof_name, u.surname prof_surname, u.patronymic prof_patronymic, sbj."name" subject_name, sbj."type" subject_type, tt."date" FROM '._schema_name.'.marks mks 
                JOIN '._schema_name.'.users u
                ON u.userid = mks.professor
                JOIN '._schema_name.'.timetable tt 
                ON mks.timetable_id = tt."id"
                JOIN '._schema_name.'.subjects sbj
                ON tt.subject = sbj."id"
                WHERE mks.student = '.pg_escape_literal($student_id).';';
        $query = pg_query($this->db, $marks_query);
        if (!$query) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_all($query);
    }


    public function get_personal_professor_info($professor_id) {
        $query = 'SELECT * FROM '._schema_name.'.professors WHERE userid ='.pg_escape_literal($professor_id);
        $result = pg_query($this->db, $query);
        if (!$result) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_assoc($result);
    }

    public function get_professor_marks($professor_id, $subject_id) {
        $marks_query = 
            'SELECT mks."id" mark_id, mks."value" mark, u."userid" stud_id, u."name" stud_name, u."surname" stud_surname, u."patronymic" stud_patronymic, sbj."name" subject_name, sbj."type" subject_type, tt."date" FROM '._schema_name.'.marks mks
                JOIN '._schema_name.'.users u
                ON u.userid = mks.student
                JOIN '._schema_name.'.timetable tt 
                ON mks.timetable_id = tt."id"
                JOIN '._schema_name.'.subjects sbj
                ON tt.subject = sbj."id"
                WHERE mks.professor = '.pg_escape_literal($professor_id).' AND sbj."id" = '.pg_escape_literal($subject_id).'
                ORDER BY tt."date" DESC;';
        $query = pg_query($this->db, $marks_query);
        if (!$query) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_all($query);
    }

    public function insert_mark($professor_id, $mark_data) {
        $mark_insert_query = 
        'INSERT INTO '._schema_name.'.marks (timetable_id, student, professor, "value") VALUES ('.
                pg_escape_literal($mark_data[0]['value']).', '.
                pg_escape_literal($mark_data[2]['value']).', '.
                pg_escape_literal($professor_id).', '.
                pg_escape_literal($mark_data[3]['value']).');';
        $query = pg_query($this->db, $mark_insert_query);
        if(!$query) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_all($query);
    }

    public function update_mark($mark_id, $mark_value, $professor_id) {
        $mark_update_query = 
            'UPDATE '._schema_name.'.marks mks 
                SET (professor, "value") = ('.pg_escape_literal($professor_id).', '.pg_escape_literal($mark_value).')
                WHERE mks."id" = '.pg_escape_literal($mark_id).';';
        $query = pg_query($this->db, $mark_update_query);
        if(!$query) {
            return json_encode(['error' => pg_last_error()]);
        }
        return pg_fetch_all($query);
    }
}
?>