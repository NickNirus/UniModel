function tblCell(value) {
    return $($("<td></td>").text(value));
}

function currentTime() {
    var time = new Date();
    return time.getFullYear() + '-' + (time.getMonth() + 1) + '-' + time.getDate();
}

function populateTimetable(timetable) {
    var i = 1;
    timetable.forEach(function (ttItem) {
        $('#timetable-table').append($("<tr></tr>")
            .append(tblCell(i++))
            .append(tblCell(ttItem.subject_name + ', ' + ttItem.subject_type))
        );
    });
}

function reloadTimetable(event) {
    $('#timetable-table tbody').empty();        
    $.get('php/student_home.php', {'date' : $('#tt-date').val()}, function (response, responseText) {
        data = JSON.parse(response);
        if(data && !data.error) {
            populateTimetable(data);
        } else {
            $('#timetable-table tbody').append($("<tr><td>Не найдено!</td></tr>"));            
        }
    });
}

function loadStudentData() {
    $.get("php/student_home.php", function (dataJson, textStatus) {
        var data = JSON.parse(dataJson);
        if(data && data.noauth == true) {
            window.location.replace("login.html");            
        }
        if (data.person.average_mark === null) {
            $('nav p.greeting').text('Добро пожаловать, ' + data.person.name + ' ' + data.person.surname + '. Ваша средняя оценка не задана.');
        } else {
            $('nav p.greeting').text('Добро пожаловать, ' + data.person.name + ' ' + data.person.surname + '. Ваша средняя оценка - ' + data.person.average_mark + '.');
        }

        data.subjects.forEach(function (subject) {
            $('#subject-table').append($("<tr></tr>")
                .append(tblCell(subject.name + ', ' + subject.type)));
        });
        if (data.marks) {
            $('#marks-table tbody').empty();
            data.marks.forEach(function (mark) {
                $('#marks-table').append($("<tr></tr>")
                    .append(tblCell(mark.date))
                    .append(tblCell(mark.subject_name + ', ' + mark.subject_type))
                    .append(tblCell(mark.prof_surname + ' ' + mark.prof_name + ' ' + mark.prof_patronymic))
                    .append(tblCell(mark.mark))
                );
            });
        } else {
            $('#marks-table tbody').append($("<tr><td>Не найдено!</td></tr>"));
        }
        if (data.timetable) {
            $('input#tt-date').val(data.timetable[0].date);
            populateTimetable(data.timetable);
        } else {
            $('input#tt-date').val(currentTime());
            $('#timetable-table tbody').append($("<tr><td>Не найдено!</td></tr>"));
        }
    });
}
$(document).ready(function () {
    loadStudentData();
    $('#tt-date').change(reloadTimetable);
});