const root = getComputedStyle(document.querySelector(':root'));
const scale = document.getElementById('Scale');
const cinema = document.getElementById('Cinema');
let cinemaMode = false;
let optiMode = 'Standard';
let toggled = true;
let inVeh = false;

cinema.oninput = (() => {
    $('.Cinema').css('height', cinema.value/2 + '%');
    localStorage.setItem('Cinema', cinema.value)
})

scale.oninput = (() => {
    $('.MainHud').css('transform', `translateX(-50%) scale(${scale.value / 100})`);
    $('.Other').css('transform', `scale(${scale.value / 100})`);
    $('.CarHud').css('transform', `scale(${scale.value / 100})`);
    $('.Settings').css('transform', `translate(-50%, -50%) scale(${scale.value / 100})`);
    localStorage.setItem('Scale', scale.value);
})

window.onload = (() => {
    let opti = localStorage.getItem('Opti');
    if (opti) {
        if (opti == 'Standard') {
            $('#StandardBtn').addClass('activeBtn');
        } else {
            $('#BetterBtn').addClass('activeBtn');
        }
        $.post('https://lean_hud/Opti', JSON.stringify({ opti: opti }));
    }

    let cinemaStorage = localStorage.getItem('Cinema');
    if (cinemaStorage) {
        $('.Cinema').css('height', cinemaStorage/2 + '%');
        cinema.value = cinemaStorage;
    }

    let scaleStorage = localStorage.getItem('Scale');
    if (scaleStorage) {
        $('.MainHud').css('transform', `translateX(-50%) scale(${scaleStorage / 100})`);
        $('.Other').css('transform', `scale(${scaleStorage / 100})`);
        $('.CarHud').css('transform', `scale(${scaleStorage / 100})`);
        $('.Settings').css('transform', `translate(-50%, -50%) scale(${scaleStorage / 100})`);
        scale.value = scaleStorage;
    }

    let Colors = document.querySelectorAll('.OptionContent > .Change > div > input[type="color"]')
    Colors.forEach(color => {
        let el = document.getElementById(color.id);
        let color2 = localStorage.getItem(color.id);
        if (color2) {
            el.value = color2;
        }
        el.oninput = (() => {
            localStorage.setItem(color.id, el.value);
        })
    })
})

const SwitchCinema = (() => {
    if (cinemaMode) {
        cinemaMode = false;
        $('#CinemaBtn').text('WYŁ');
        $('.CinemaMode').hide();
        $('.MainHud').css('display', 'flex');
        $('.Other').css('display', 'flex');
        if (inVeh) {
            $('.CarHud').css('display', 'flex');
        }
        $.post('https://lean_hud/SwitchCinema', JSON.stringify({ toggle: false }))
    } else {
        cinemaMode = true;
        $('#CinemaBtn').text('WŁ');
        $('.CinemaMode').show();
        $('.MainHud').hide();
        $('.Other').hide();
        $('.CarHud').hide();
        $.post('https://lean_hud/SwitchCinema', JSON.stringify({ toggle: true }))
    }
})

const SwitchOpti = ((opti) => {
    if (opti !== optiMode) {
        if (opti == 'Standard') {
            $('#BetterBtn').removeClass('activeBtn');
            $('#StandardBtn').addClass('activeBtn');
            optiMode = 'Standard';
        } else {
            $('#StandardBtn').removeClass('activeBtn');
            $('#BetterBtn').addClass('activeBtn');
            optiMode = 'Better';
        }
        $.post('https://lean_hud/Opti', JSON.stringify({ opti: opti }));
    }
})

window.addEventListener("message", (event) => {
    let data = event.data;
    switch(data.action) {
        case 'SHOW_HUD':
            if (!cinemaMode) {
                $('.MainHud').css('display', 'flex');
                $('.ID').text(data.id);
                $('.UID').text(data.uid);
                $('.WaterMark').css('display', 'flex');
                $('.WaterMark').fadeIn(100);
            }
            break;
        case 'UPDATE_HUD':
            let hudData = data.hud;
            for (const [key, value] of Object.entries(hudData)) {
                let storageColor = localStorage.getItem(`${key}Color`);
                if (storageColor) {
                    $(`#${key}`).css({'background': `linear-gradient(to top, ${storageColor} ${value}%, white 0%)`, '-webkit-text-fill-color': 'transparent', '-webkit-background-clip': 'text'})
                } else {
                    $(`#${key}`).css({'background': `linear-gradient(to top, ${root.getPropertyValue('--maincolor')} ${value}%, white 0%)`, '-webkit-text-fill-color': 'transparent', '-webkit-background-clip': 'text'})
                }

                if (key == 'Armor') {
                    if (value < 1) {
                        $(`#${key}`).fadeOut(100);
                    } else {
                        $(`#${key}`).fadeIn(100);
                    }
                } else if (key == 'Oxygen') {
                    if (value < 99) {
                        $(`#${key}`).fadeIn(100);
                    } else {
                        $(`#${key}`).fadeOut(100);
                    }
                }
            }
            break;
        case 'UPDATE_VOICE':
            let voice = data.voice;
            let storageColor = localStorage.getItem(`MicColor`);
            var micColor = root.getPropertyValue('--maincolor');
            if (storageColor) {
                micColor = storageColor;
            }
            switch(voice.mode) {
                case 'Whisper':
                    $(`#Mic`).css({'background': `linear-gradient(to top, ${micColor} 30%, white 0%)`, '-webkit-text-fill-color': 'transparent', '-webkit-background-clip': 'text'})
                    break;
                case 'Normal':
                    $(`#Mic`).css({'background': `linear-gradient(to top, ${micColor} 50%, white 0%)`, '-webkit-text-fill-color': 'transparent', '-webkit-background-clip': 'text'})
                    break;
                case 'Shouting':
                    $(`#Mic`).css({'background': `linear-gradient(to top, ${micColor} 100%, white 0%)`, '-webkit-text-fill-color': 'transparent', '-webkit-background-clip': 'text'})
                    break; 
            }

            if (voice.isTalking) {
                $('#Mic').css('filter', 'brightness(140%)');
            } else {
                $('#Mic').css('filter', 'brightness(100%)');
            }
            break;
        case 'SHOW_CARHUD':
            if (!cinemaMode) {
                $('.CarHud').css('display', 'flex');
                $('.CarHud').fadeIn(100);
                inVeh = true;
            }
            break;
        case 'HIDE_CARHUD':
            $('.CarHud').fadeOut(100);
            inVeh = false;
            break;
        case 'UPDATE_CARHUD':
            let carData = data.car;
            for (const [key, value] of Object.entries(carData)) {
                if (key == 'Fuel') {
                    $('.FuelFill').animate({
                        width: value + '%'
                    }, 100)
                } else if (key == 'Belt') {
                    if (value) {
                        $('#Belt').css('color', root.getPropertyValue('--maincolor'));
                    } else {
                        $('#Belt').css('color', 'white');
                    }
                } else {
                    $(`#${key}`).text(value);
                }
            }
            break;
        case 'SHOW_WEAPONHUD':
            if (!cinemaMode) {
                $('.WeaponHud').css('display', 'flex');
                $('.WeaponHud').fadeIn(100);
            }
            break;
        case 'HIDE_WEAPONHUD':
            $('.WeaponHud').fadeOut(100);
            break;
        case 'UPDATE_WEAPONHUD':
            let weapon = data.weapon;
            $('#WeaponImage').attr('src', `img/${weapon.name}.png`);
            $('#Magazine').text(weapon.magazine);
            $('#Ammo').text(weapon.ammo);
            break;
        case 'ADD_NOTIFY':
            let $Notify = $(`<div class="Notify">
                <i class="fa-solid fa-bell"></i>
                <div>
                    <span style="font-size: 1.5vh;">Powiadomienie</span>
                    <span>${data.text}</span>
                </div>
            </div>`)
            $('.NotifyList').prepend($Notify);
            $Notify.addClass('slide-in');
            setTimeout(() => {
                $Notify.removeClass('slide-in');
                setTimeout(() => {
                    $Notify.addClass('slide-out');
                    setTimeout(() => {
                        $Notify.removeClass('slide-out');
                        $Notify.remove();
                    }, 299);
                }, data.time || 5000);
            }, 299);
            break;
        case 'OPEN_SETTINGS':
            $('.Settings').fadeIn(100);
            break;
        case 'UPDATE_CLOCK':
            $('.Clock').text(data.clock);
            break;
        case 'TOGGLE_HUD':
            if (toggled) {
                $('.MainHud').animate({
                    bottom: '-15%'
                }, 200)
                toggled = false;
            } else {
                $('.MainHud').animate({
                    bottom: '0.8%'
                }, 200)
                toggled = true;
            }
            break;
    }
})

document.onkeydown = ((e) => {
    if (e.which == 27) {
        $('.Settings').fadeOut(100);
        $.post('https://lean_hud/CloseSettings');
    }
})