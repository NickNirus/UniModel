-- 
-- Source Server         : postgres-default
-- Source Server Version : 90601
-- Source Host           : localhost:5432
-- Source Database       : UniModel
-- Source Schema         : rusin_n_408_db

-- Target Server Type    : PGSQL
-- Target Server Version : 90601
-- File Encoding         : 65001

-- Date: 2017-12-16 16:49:09
-- 

-- ----------------------------
-- Sequence structure for users_id_seq
-- ----------------------------
DROP SCHEMA IF EXISTS rusin_n_408_db CASCADE;
CREATE SCHEMA rusin_n_408_db;
-- ----------------------------
-- Sequence structure for users_id_seq
-- ----------------------------
CREATE SEQUENCE "rusin_n_408_db"."users_id_seq"
 INCREMENT 1
 MINVALUE 1
 MAXVALUE 9223372036854775807
 START 1
 CACHE 1;
SELECT setval('"rusin_n_408_db"."users_id_seq"', 39925, true);

-- ----------------------------
-- Sequence structure for marks_id_seq
-- ----------------------------
CREATE SEQUENCE "rusin_n_408_db"."marks_id_seq"
 INCREMENT 1
 MINVALUE 1
 MAXVALUE 9223372036854775807
 START 1
 CACHE 1;
-- SELECT setval('"rusin_n_408_db"."marks_id_seq"', 11, true);

-- ----------------------------
-- Sequence structure for subjects_id_seq
-- ----------------------------
CREATE SEQUENCE "rusin_n_408_db"."subjects_id_seq"
 INCREMENT 1
 MINVALUE 1
 MAXVALUE 9223372036854775807
 START 1
 CACHE 1;
SELECT setval('"rusin_n_408_db"."subjects_id_seq"', 5, true);

-- ----------------------------
-- Sequence structure for timetable_id_seq
-- ----------------------------
CREATE SEQUENCE "rusin_n_408_db"."timetable_id_seq"
 INCREMENT 1
 MINVALUE 1
 MAXVALUE 9223372036854775807
 START 1
 CACHE 1;
SELECT setval('"rusin_n_408_db"."timetable_id_seq"', 14, true);

-- ----------------------------
-- Table structure for marks
-- ----------------------------
CREATE TABLE "rusin_n_408_db"."marks" (
"timetable_id" int4 NOT NULL,
"student" int4 NOT NULL,
"professor" int4 NOT NULL,
"value" int2 NOT NULL,
"id" int4 DEFAULT nextval('"rusin_n_408_db"."marks_id_seq"'::regclass) NOT NULL
)
WITH (OIDS=FALSE)

;

-- ----------------------------
-- Table structure for subject_participation
-- ----------------------------
CREATE TABLE "rusin_n_408_db"."subject_participation" (
"subject" int4 NOT NULL,
"userid" int4 NOT NULL
)
WITH (OIDS=FALSE)

;

-- ----------------------------
-- Table structure for subjects
-- ----------------------------
CREATE TABLE "rusin_n_408_db"."subjects" (
"id" int4 DEFAULT nextval('"rusin_n_408_db"."subjects_id_seq"'::regclass) NOT NULL,
"name" varchar(255) COLLATE "default" NOT NULL,
"type" varchar(255) COLLATE "default"
)
WITH (OIDS=FALSE)

;

-- ----------------------------
-- Table structure for timetable
-- ----------------------------
CREATE TABLE "rusin_n_408_db"."timetable" (
"id" int4 DEFAULT nextval('"rusin_n_408_db"."timetable_id_seq"'::regclass) NOT NULL,
"date" date NOT NULL,
"subject" int4 NOT NULL
)
WITH (OIDS=FALSE)

;

-- ----------------------------
-- Table structure for users
-- ----------------------------
CREATE TABLE "rusin_n_408_db"."users" (
"userid" int4 DEFAULT nextval('"rusin_n_408_db"."users_id_seq"'::regclass)  NOT NULL,
"login" varchar(255) COLLATE "default",
"password" varchar(40) COLLATE "default",
"salt" varchar(16) COLLATE "default",
"name" varchar(128) COLLATE "default" NOT NULL,
"surname" varchar(128) COLLATE "default" NOT NULL,
"patronymic" varchar(255) COLLATE "default",
"birthday" date NOT NULL,
"professor" bool DEFAULT false NOT NULL,
"average_mark" float4 DEFAULT NULL,
"token" varchar(32) COLLATE "default"
)
WITH (OIDS=FALSE)

;

-- ----------------------------
-- View structure for auth
-- ----------------------------
CREATE VIEW "rusin_n_408_db"."auth" AS 
 SELECT u.userid,
    u.login,
    u.password,
    u.salt,
    u.professor,
    u.token
   FROM "rusin_n_408_db"."users" u;

-- ----------------------------
-- View structure for professors
-- ----------------------------
CREATE VIEW "rusin_n_408_db"."professors" AS 
 SELECT u.userid,
    u.name,
    u.surname,
    u.patronymic,
    u.birthday
   FROM "rusin_n_408_db"."users" u
  WHERE (u.professor = true);

-- ----------------------------
-- View structure for students
-- ----------------------------
CREATE VIEW "rusin_n_408_db"."students" AS 
 SELECT u.userid,
    u.name,
    u.surname,
    u.patronymic,
    u.birthday,
    u.average_mark
   FROM "rusin_n_408_db"."users" u
  WHERE (u.professor = false);

-- ----------------------------
-- Alter Sequences Owned By 
-- ----------------------------
ALTER SEQUENCE "rusin_n_408_db"."marks_id_seq" OWNED BY "rusin_n_408_db"."marks"."id";
ALTER SEQUENCE "rusin_n_408_db"."subjects_id_seq" OWNED BY "rusin_n_408_db"."subjects"."id";
ALTER SEQUENCE "rusin_n_408_db"."timetable_id_seq" OWNED BY "rusin_n_408_db"."timetable"."id";

-- ----------------------------
-- Trigger Function check_mark_creator
-- ----------------------------

CREATE OR REPLACE FUNCTION "rusin_n_408_db"."check_mark_creator"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
BEGIN
	IF EXISTS(
		SELECT * 
			FROM "rusin_n_408_db"."timetable" tt 
			JOIN "rusin_n_408_db"."subjects" sbj ON tt."subject" = sbj."id" 
			JOIN "rusin_n_408_db"."subject_participation" sp_p ON tt."subject" = sp_p."subject" 
			JOIN "rusin_n_408_db"."subject_participation" sp_s ON tt."subject" = sp_s."subject" 
			WHERE tt."id" = NEW."timetable_id" AND sp_p."userid" = NEW."professor" AND sp_s."userid" = NEW."student"
		) 
	THEN
		/*the condition is satisfied*/
		RETURN NEW;
	ELSE
		RETURN NULL;
	END IF;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE;

-- ----------------------------
-- Trigger Function update_avg_mark
-- ----------------------------

CREATE OR REPLACE FUNCTION "rusin_n_408_db"."update_avg_mark"() 
	RETURNS "pg_catalog"."trigger" AS $BODY$
	DECLARE
		mark_sum FLOAT;
		mark_count int;
		new_avg_mark FLOAT;
	BEGIN
		SELECT COUNT("m"."value"), SUM("m"."value") INTO mark_count, mark_sum FROM "rusin_n_408_db"."marks" m WHERE m."student" = NEW."student";

		new_avg_mark := mark_sum/mark_count;

		UPDATE "rusin_n_408_db"."users" u SET average_mark = new_avg_mark 
			WHERE u."userid" = NEW."student";
		RETURN NEW;
	END;
$BODY$ 
	LANGUAGE 'plpgsql' VOLATILE;

-- ----------------------------
-- Triggers structure for table marks
-- ----------------------------
CREATE TRIGGER "update_average_mark_trigger" AFTER INSERT OR UPDATE OF "value" ON "rusin_n_408_db"."marks"
FOR EACH ROW
EXECUTE PROCEDURE "rusin_n_408_db"."update_avg_mark"();
CREATE TRIGGER "check_mark_creator_trigger" BEFORE INSERT ON "rusin_n_408_db"."marks"
FOR EACH ROW
EXECUTE PROCEDURE "rusin_n_408_db"."check_mark_creator"();

-- ----------------------------
-- Checks structure for table marks
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."marks" ADD CHECK (((value > 0) AND (value <= 5)));

-- ----------------------------
-- Rules structure for table marks
-- ----------------------------
CREATE OR REPLACE RULE "rule_marks_delete_protect" AS ON DELETE TO "rusin_n_408_db"."marks" DO NOTHING;;

-- ----------------------------
-- Primary Key structure for table marks
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."marks" ADD PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table subject_participation
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."subject_participation" ADD PRIMARY KEY ("subject", "userid");

-- ----------------------------
-- Primary Key structure for table subjects
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."subjects" ADD PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table timetable
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."timetable" ADD PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table users
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."users" ADD PRIMARY KEY ("userid");

-- ----------------------------
-- Foreign Key structure for table "rusin_n_408_db"."marks"
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."marks" ADD FOREIGN KEY ("timetable_id") REFERENCES "rusin_n_408_db"."timetable" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "rusin_n_408_db"."marks" ADD FOREIGN KEY ("professor") REFERENCES "rusin_n_408_db"."users" ("userid") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "rusin_n_408_db"."marks" ADD FOREIGN KEY ("student") REFERENCES "rusin_n_408_db"."users" ("userid") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Key structure for table "rusin_n_408_db"."subject_participation"
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."subject_participation" ADD FOREIGN KEY ("subject") REFERENCES "rusin_n_408_db"."subjects" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE "rusin_n_408_db"."subject_participation" ADD FOREIGN KEY ("userid") REFERENCES "rusin_n_408_db"."users" ("userid") ON DELETE CASCADE ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Key structure for table "rusin_n_408_db"."timetable"
-- ----------------------------
ALTER TABLE "rusin_n_408_db"."timetable" ADD FOREIGN KEY ("subject") REFERENCES "rusin_n_408_db"."subjects" ("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- ----------------------------
-- ----------------------------
-- Records
-- ----------------------------
-- ----------------------------

-- ----------------------------
-- Records of users
-- ----------------------------
BEGIN;
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39906', 'longine_v', '63e42c7a7e44e6afeae763f63e8ca8b8ddb2bf2e', 'UFv8YjkRSoiLkhZi', 'Всеволод', 'Лонгине', null, '1996-12-09', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39907', 'makarov_m', 'c9b9fbd9aa776888863667ffe85fe6a5171552bf', 'AtF+Q1oDBjSPZAyv', 'Михаил', 'Макаров', null, '1995-10-19', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39908', 'zelenskiy_s', 'b70cf0a3e3525dd753c1b0a84d504c9a9e991981', 'MZYf0bRXOVD0i1mz', 'Святослав', 'Зеленский', null, '1995-11-10', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39909', 'seny_a', '8638e9665427c748dd37fac6778f572b80e83186', 'MTHSLzmLD31MpdEI', 'Анастасия', 'Сень', null, '1996-02-01', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39910', 'tihonov_n', '3e4f7a38f80471c5dc55c09909963e598f7b6c81', 'DKoe3/BFrWQvDIvp', 'Николай', 'Тихонов', null, '1996-04-30', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39911', 'temnikov_s', '28e4024cb94c1f4a2060fc6e1990cf9782ebd0b8', 'Izt8NDXtpC1vOKLr', 'Степан', 'Темников', null, '1996-07-07', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39912', 'voytovich_d', '23ce6e0ef4f9693d255bcefabd167bae00083a4e', 'a0TCplFpvvpYddfC', 'Дмитрий', 'Войтович', null, '1995-01-20', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39913', 'sorokina_s', 'e088a62fef42940e3cf27d693b54f333595c7ff2', 'AugiPc2pd9i0wPe8', 'Светлана', 'Сорокина', null, '1996-02-09', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39914', 'chernova_m', 'dda825892ca8216ac3b13beb02a0d2f45cb9cd6b', 'zatEhZXNePk/gu3l', 'Мария', 'Чернова', null, '1996-06-18', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39915', 'dashevskiy_d', '15111aa0892c0dca3274606defea434b52468116', 'YAxeZhGrrt+I2S5b', 'Даниил', 'Дашевский', null, '1995-05-11', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39916', 'hohlov_m', '3d5aae157670f286898cff81085cd062292ce24e', 'JHiJ7aO7iZl5NYZn', 'Михаил', 'Хохлов', null, '1997-03-22', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39917', 'alekseev_e', 'b2a31d5b325115eb3fc69faf8add51adc0bae80e', 'B+nHY7fBLUbRxQAU', 'Евгений', 'Алексеев', null, '1996-01-15', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39918', 'kilin_r', '9d75555449aedb0a182e740ecd07eff3c8fc3e55', 'RaFjZpM/YhCOim7c', 'Роман', 'Килин', null, '1996-09-18', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39919', 'pogorelova_i', '9b076658c0f9742140c2d791ce1ccee0b11852b3', 'Y/c6SgQnifd6hkUT', 'Инна', 'Погорелова', null, '1996-08-08', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39920', 'goncharov_a', '9e3e1362a5a61e9ed7751af6340f816cdbba4592', '9l6uwYV+JHgt3WU/', 'Артём', 'Гончаров', null, '1996-10-20', 'f');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39921', 'bondaryov_p', 'b25105b6f7185a651254bde01dc79cbb9ac75279', 'tRkT35fgMsFs43XN', 'Петр', 'Бондарёв', 'Владимирович', '1976-08-04', 't');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39922', 'vyazovskaya_a', '67ec8511db8f03609dd254773d2e39b4c1c42647', '3VkPgcSMTHXR11uG', 'Анна', 'Вязовская', 'Аркадьевна', '1980-09-21', 't');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39923', 'fedchenko_e', '7b36b7a2ef50d6173605008db7d1f6924710620b', 'XFX065yu2yKavddr', 'Елена', 'Федченко', 'Борисовна', '1971-11-17', 't');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39924', 'smirenko_k', 'd3a05461dbb6b569b07eb343b208c17b679bea42', 'juIklMji4BtK4KY8', 'Кирилл', 'Смиренко', 'Леонидович', '1968-12-03', 't');
INSERT INTO "rusin_n_408_db"."users" ("userid", "login", "password", "salt", "name", "surname", "patronymic", "birthday", "professor") VALUES ('39925', 'yurchak_a', 'a12d370a95ae11222e2fdeab9149dd564959b885', 'uwlVc7LdE4riHBn6', 'Алексей', 'Юрчак', 'Михаилович', '1960-01-22', 't');
COMMIT;

-- ----------------------------
-- Records of subjects
-- ----------------------------
BEGIN;
INSERT INTO "rusin_n_408_db"."subjects" ("id", "name", "type") VALUES ('1', 'Алгебра', 'лекция');
INSERT INTO "rusin_n_408_db"."subjects" ("id", "name", "type") VALUES ('2', 'Геометрия', 'лекция');
INSERT INTO "rusin_n_408_db"."subjects" ("id", "name", "type") VALUES ('3', 'Математический анализ', 'лекция');
INSERT INTO "rusin_n_408_db"."subjects" ("id", "name", "type") VALUES ('4', 'Теоретическая механика', 'лекция');
INSERT INTO "rusin_n_408_db"."subjects" ("id", "name", "type") VALUES ('5', 'Уравнения математической физики', 'лекция');
COMMIT;

-- ----------------------------
-- Records of subject_participation
-- ----------------------------
BEGIN;
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39906');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39907');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39908');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39909');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39910');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39911');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39912');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39913');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39914');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39915');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39916');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39917');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39918');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39919');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39920');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39921');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('1', '39922');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39906');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39907');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39908');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39909');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39910');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39911');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39912');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39913');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39914');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39915');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('2', '39922');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39906');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39907');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39908');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39909');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39910');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39911');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39912');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39913');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39914');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39915');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39916');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39917');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39918');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39919');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39920');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39923');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39924');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('3', '39925');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39906');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39907');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39908');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39909');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39910');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39911');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39912');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39913');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39914');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39915');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39923');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('4', '39925');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('5', '39911');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('5', '39912');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('5', '39913');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('5', '39914');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('5', '39915');
INSERT INTO "rusin_n_408_db"."subject_participation" ("subject", "userid") VALUES ('5', '39923');
COMMIT;

-- ----------------------------
-- Records of timetable
-- ----------------------------

BEGIN;
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('1', CURRENT_DATE - 2, '2');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('2', CURRENT_DATE - 2, '3');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('3', CURRENT_DATE - 2, '4');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('4', CURRENT_DATE - 2, '1');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('5', CURRENT_DATE - 1, '1');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('6', CURRENT_DATE - 1, '2');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('7', CURRENT_DATE - 1, '3');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('8', CURRENT_DATE, '2');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('9', CURRENT_DATE, '3');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('10', CURRENT_DATE, '4');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('11', CURRENT_DATE, '5');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('12', CURRENT_DATE + 1, '2');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('13', CURRENT_DATE + 1, '3');
INSERT INTO "rusin_n_408_db"."timetable" ("id", "date", "subject") VALUES ('14', CURRENT_DATE + 1, '5');
COMMIT;

-- ----------------------------
-- ----------------------------
-- User
-- ----------------------------
-- ----------------------------

-- ----------------------------
-- Create role rusin_n_408_db_unimodel_user
-- ----------------------------

CREATE ROLE rusin_n_408_db_unimodel_user;
ALTER ROLE rusin_n_408_db_unimodel_user WITH NOSUPERUSER NOINHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57f704d7af717ae6488900a3e968a7eda';

-- ----------------------------
-- Grant schema usage
-- ----------------------------

GRANT USAGE ON SCHEMA rusin_n_408_db TO rusin_n_408_db_unimodel_user;

-- ----------------------------
-- Grant table usage
-- ----------------------------

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE "rusin_n_408_db"."users" TO rusin_n_408_db_unimodel_user;
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE "rusin_n_408_db"."auth" TO rusin_n_408_db_unimodel_user;
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE "rusin_n_408_db"."marks" TO rusin_n_408_db_unimodel_user;
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE "rusin_n_408_db"."professors" TO rusin_n_408_db_unimodel_user;
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE "rusin_n_408_db"."students" TO rusin_n_408_db_unimodel_user;
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE "rusin_n_408_db"."subject_participation" TO rusin_n_408_db_unimodel_user;
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE "rusin_n_408_db"."subjects" TO rusin_n_408_db_unimodel_user;
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE "rusin_n_408_db"."timetable" TO rusin_n_408_db_unimodel_user;

-- ----------------------------
-- Grant sequence usage
-- ----------------------------

GRANT USAGE ON SEQUENCE "rusin_n_408_db"."users_id_seq" TO rusin_n_408_db_unimodel_user;
GRANT USAGE ON SEQUENCE "rusin_n_408_db"."subjects_id_seq" TO rusin_n_408_db_unimodel_user;
GRANT USAGE ON SEQUENCE "rusin_n_408_db"."marks_id_seq" TO rusin_n_408_db_unimodel_user;
GRANT USAGE ON SEQUENCE "rusin_n_408_db"."timetable_id_seq" TO rusin_n_408_db_unimodel_user;
