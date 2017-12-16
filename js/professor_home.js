// Timetable
function tblCell(value) {
    return $("<td></td>").text(value);
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
            .append(tblCell(ttItem.subject_name + ', ' + ttItem.subject_type)
                .append($('<button class="btn btn-xs btn-inline pull-right" value="['+ttItem.subject_id + ',' + ttItem.timetable_id + ']"></button>').text("Просмотреть оценки"))
            )
        );
    });
    $('#timetable-table button').click(loadMarks);    
}

function reloadTimetable(event) {
    $('#timetable-table tbody').empty();
    if($('#tt-date').val() != currentTime()) {
        $('#button-add-mark').prop('disabled', true);
    } else {
        $('#button-add-mark').prop('disabled', false);
    }
    $.get('php/professor_home.php', {'date' : $('#tt-date').val()}, function (response, responseText) {
        data = JSON.parse(response);
        if(data && !data.error) {
            populateTimetable(data);
        } else {
            $('#timetable-table tbody').append($("<tr><td>Не найдено!</td></tr>"));            
        }
    });
}

// Marks

function updateMark(event) {
    var markId = $(this).val();
    $.post("php/marks.php", {'edit_mark_id':markId, 'mark_value':$('#mark'+markId).val()}, function(response, responseText) {
        console.log(response, responseText);
        $(this).parent().parent().removeClass('bg-info');
    });
}

function loadMarks(event) {
    $.get("php/marks.php", {'subject_id': JSON.parse($(this).val())[0], 'timetable_id':JSON.parse($(this).val())[1]}, function(response, responseText) {
        var data = JSON.parse(response);
        
        if(!data) {
            $('#marks-table tbody').empty();
            $('#marks-table tbody').append($("<tr><td>Нема!</td></tr>"));
            return;
        }

        if(data.noauth == true) {
            window.location.replace("login.html");
        }

        $('#marks-table tbody').empty();
        $('#panel-marks .panel-title').text('Оценки по предмету: ' + data.marks[0].subject_name + ', ' + data.marks[0].subject_type);        
        data.marks.forEach(function (mark) {
            $('#marks-table').append($('<tr></tr>')
                .append(tblCell(mark.date))
                // .append(tblCell(mark.subject_name + ', ' + mark.subject_type))
                .append(tblCell(mark.stud_surname + ' ' + mark.stud_name + (mark.prof_patronymic === undefined ? '' : ' ' + mark.prof_patronymic)))
                .append($("<td></td>")
                    .append($('<input id="mark'+mark.mark_id+'" type="number" min="1" max="5" value="'+mark.mark+'"></input>'))
                    )
                .append($("<td></td>")                
                    .append($('<button class="btn btn-xs btn-inline" value="'+mark.mark_id+'"></button>').text("Сохранить оценку"))
                    )
                );
            });
        $('#marks-table button').click(updateMark);
        $('#marks-table input').change(function(event) {
            $(this).parent().parent().addClass('bg-info');
        });

        $('#input-select-student').empty();
        data.students.forEach(function(student) {
            $('#form-add-mark select').append($('<option value="'+student.userid+'">'+student.surname + ' ' + student.name + (student.patronymic === null ? '' : ' ' + student.patronymic)+'</option>'));
        });

        $('#panel-marks').removeClass('hidden');
        $('#input-timetable').val(data.timetable_id);
    });
}

// Init

function loadProfessorData() {
    $.get("php/professor_home.php", function (dataJson, textStatus) {
        var data = JSON.parse(dataJson);

        if(data && data.noauth == true) {
            window.location.replace("login.html");
        }

        $('nav p.greeting').text('Добро пожаловать, ' + data.person.name + ' ' + data.person.patronymic + '.');

        data.subjects.forEach(function (subject) {
            $('#subject-table tbody').append($("<tr></tr>")
                .append($("<td></td>")
                    .append($('<span></span>').text(subject.name + ', ' + subject.type))
                    // .append($('<button class="btn btn-xs btn-inline pull-right" value="'+subject.id+'"></button>').text("Просмотреть оценки"))
                ));
        });

        if (data.timetable) {
            $('input#tt-date').val(data.timetable[0].date);
            populateTimetable(data.timetable);
        } else {
            $('input#tt-date').val(currentTime());
            $('#timetable-table tbody').append($("<tr><td>Не найдено!</td></tr>"));
        }

        $('#input-date').val(currentTime());
    });
}

$(document).ready(function () {
    loadProfessorData();
    $('#tt-date').change(reloadTimetable);
    $('#button-add-mark').click(function(event) {
        $($('#panel-marks div.panel-heading>div.row')[1]).removeClass('hidden');
    });
    $('#button-cancel-add-mark').click(function(event) {
        $($('#panel-marks div.panel-heading>div.row')[1]).addClass('hidden');
    });

    $('#form-add-mark').submit(function(event){
        event.preventDefault();
        var form = $('#form-add-mark').serializeArray();
        $.post("php/marks.php", {'add_mark':JSON.stringify(form)}, function(response, responseText) {
            console.log(response, responseText);
            
        });
    });
});