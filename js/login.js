$(window).on('load', function () {
    $("#signin-form").submit(function (event) {
        $.post("php/login.php",
            $("#signin-form").serialize(),
            function (dataJson, textStatus, jqXHR) {
                var data = JSON.parse(dataJson);
                if (data.success) {
                    window.location.replace(data.redirect);
                } else if (data.error) {
                    $("div.alert").text(data.error).removeClass('hidden');
                }
            });
        event.preventDefault();
    });
});