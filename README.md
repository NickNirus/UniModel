## База данных университета
#### Зависимости
- Composer
#### Установка
- Выполнить в командной строке
```sh
$ cd php
$ php composer.phar install
```
 - Импортировать базу данных PostgreSQL с помощью файла `/sql/postgresql_UniModel_import.sql`.

После отработки можно входить через `login.html`.
#### Авторизация
У всех студентов пароли `studentPass1`, у преподавателей `profPass2`. Несколько логинов, чтобы не лезть в базу:
 - Студенты: `longine_v`, `seny_a`, `voytovich_d`;
 - Преподаватели: `vyazovskaya_a`, `fedchenko_e`, `yurchak_a`.