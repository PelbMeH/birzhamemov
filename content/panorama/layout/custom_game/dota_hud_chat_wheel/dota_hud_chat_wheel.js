var favourites = new Array();
var nowrings = 8;
var selected_sound_current = undefined;
var nowselect = 0;
var default_button = null
var itemTypes = [Items_sounds, Items_sprays, Items_toys];
var rings = 
[
    [
        ["","","","","","","",""],
        [true,true,true,true,true,true,true,true],
    ],
]

for (var itemType_find of itemTypes) 
{
    for (var item_find of itemType_find) 
    {
        let current_ring = rings[rings.length - 1]
        if (current_ring[0].length < 8)
        {
            current_ring[0].push($.Localize("#"+item_find[4]))
            current_ring[1].push(true)
            current_ring[2].push(Number(item_find[0]))
        }
        else
        {
            rings.push([[$.Localize("#"+item_find[4])],[true],[Number(item_find[0])]])
        }
    }
}

if (rings[rings.length - 1].length < 8)
{
    for ( var i = 0; i <= 9-rings[rings.length - 1].length; i++ )
    {
        rings[rings.length - 1][0].push("")
        rings[rings.length - 1][1].push(false)
        rings[rings.length - 1][2].push(0)
    }
}

function StartWheel() 
{
    selected_sound_current = undefined;
    $("#Wheel").visible = true;
    $("#Bubble").visible = true;
    $("#PhrasesContainer").visible = true;
    $("#ChangeWheelButtons").visible = true;
    $("#ChangeWheelButtonLabel").text = (nowselect + 1) + " / " + rings.length 
    $("#PhrasesContainer").RemoveAndDeleteChildren();

    for ( var i = 0; i < 8; i++ )
    {
        $.CreatePanel(`Button`, $("#PhrasesContainer"), `Phrase${i}`, {
            class: `MyPhrases`,
            onmouseover: `OnMouseOver(${i})`,
            onmouseout: `OnMouseOut(${i})`,
        });
        $("#Phrase"+i).BLoadLayoutSnippet("Phrase");
        $("#Phrase"+i).GetChild(0).GetChild(0).visible = rings[0][1][i];

        if (nowselect != 0)
        {
            var phase_deactive = true
            var player_table = CustomNetTables.GetTableValue("birzhashop", String(Players.GetLocalPlayer()))
            for (var d = 0; d <= Object.keys(player_table.player_items).length; d++) 
            {
                if (player_table.player_items[d])
                {
                    if (player_table.player_items[d] == rings[nowselect][2][i]) 
                    {
                        phase_deactive = false
                        break
                    } 
                }
            }
            
            if (rings[nowselect][1][i] == false)
             {
                $("#Phrase"+i).style.visibility = "collapse"
            } else {
                $("#Phrase"+i).style.visibility = "visible"
            }

            $("#Phrase"+i).GetChild(0).GetChild(0).text = $.Localize(rings[nowselect][0][i]);

            if (phase_deactive) {   
                var blocked = $.CreatePanel("Panel", $("#Phrase"+i).GetChild(0), "" );
                blocked.AddClass("BlockChatWheel");
                $("#Phrase"+i).GetChild(0).style.washColor = "red"
            }
        } else {
            let name = $.Localize("#chatwheel_birzha_null")
            var player_table = CustomNetTables.GetTableValue("birzhainfo", String(Players.GetLocalPlayer()))
            if (player_table)
            {
                if (player_table.chat_wheel)
                {
                    for (var itemType of itemTypes) 
                    {
                        for (var item of itemType) 
                        {
                            if (item[0] == String(player_table.chat_wheel[i + 1])) 
                            {
                                name = $.Localize("#" + item[4]);
                                break;
                            }
                        }
                    }
                }
            }
            $("#Phrase"+i).GetChild(0).GetChild(0).text = name;
        }
    }
}

function LeftButton()
{
    if (nowselect - 1 < 0)
    {
        nowselect = rings.length - 1
    } else {
        nowselect = nowselect - 1
    }
    $("#ChangeWheelButtonLabel").text = (nowselect + 1) + " / " + rings.length
    $("#PhrasesContainer").RemoveAndDeleteChildren();
    for ( var i = 0; i < 8; i++ )
    {
        let properities_for_panel = {
            class: `MyPhrases`,
            onmouseover: `OnMouseOver(${i})`,
            onmouseout: `OnMouseOut(${i})`,
        };

        $.CreatePanel(`Button`, $("#PhrasesContainer"), `Phrase${i}`, properities_for_panel);
        $("#Phrase"+i).BLoadLayoutSnippet("Phrase");

        if (nowselect != 0)
        {
            var phase_deactive = true
            var player_table = CustomNetTables.GetTableValue("birzhashop", String(Players.GetLocalPlayer()))
            for (var d = 0; d <= Object.keys(player_table.player_items).length; d++) 
            {
                if (player_table.player_items[d])
                {
                    if (player_table.player_items[d] == rings[nowselect][2][i]) 
                    {
                        phase_deactive = false
                        break
                    } 
                }
            }

             if (rings[nowselect][1][i] == false)
             {
                $("#Phrase"+i).style.visibility = "collapse"
             } else {
                $("#Phrase"+i).style.visibility = "visible"
             }

            $("#Phrase"+i).GetChild(0).GetChild(0).text = $.Localize(rings[nowselect][0][i]);

            if (phase_deactive) {   
                var blocked = $.CreatePanel("Panel", $("#Phrase"+i).GetChild(0), "" );
                blocked.AddClass("BlockChatWheel");
                $("#Phrase"+i).GetChild(0).style.washColor = "red"
            }
        } else {
            let name = $.Localize("#chatwheel_birzha_null")
            var player_table = CustomNetTables.GetTableValue("birzhainfo", String(Players.GetLocalPlayer()))
            if (player_table)
            {
                if (player_table.chat_wheel)
                {
                    for (var itemType of itemTypes) 
                    {
                        for (var item of itemType) 
                        {
                            if (item[0] == String(player_table.chat_wheel[i + 1])) 
                            {
                                name = $.Localize("#" + item[4]);
                                break;
                            }
                        }
                    } 
                }
            }
            $("#Phrase"+i).GetChild(0).GetChild(0).text = name;
        }
    }
}

function RightButton()
{
    if (nowselect + 1 > (rings.length - 1))
    {
        nowselect = 0
    } else {
        nowselect = nowselect + 1
    }
    $("#ChangeWheelButtonLabel").text = (nowselect + 1) + " / " + rings.length
    $("#PhrasesContainer").RemoveAndDeleteChildren();
    for ( var i = 0; i < 8; i++ )
    {
        let properities_for_panel = {
            class: `MyPhrases`,
            onmouseover: `OnMouseOver(${i})`,
            onmouseout: `OnMouseOut(${i})`,
        };

        $.CreatePanel(`Button`, $("#PhrasesContainer"), `Phrase${i}`, properities_for_panel);
        $("#Phrase"+i).BLoadLayoutSnippet("Phrase");

        if (nowselect != 0)
        {
            var phase_deactive = true
            var player_table = CustomNetTables.GetTableValue("birzhashop", String(Players.GetLocalPlayer()))
            for (var d = 0; d <= Object.keys(player_table.player_items).length; d++) 
            {
                if (player_table.player_items[d])
                {
                    if (player_table.player_items[d] == rings[nowselect][2][i]) 
                    {
                        phase_deactive = false
                        break
                    } 
                }
            }

             if (rings[nowselect][1][i] == false)
             {
                $("#Phrase"+i).style.visibility = "collapse"
             } else {
                $("#Phrase"+i).style.visibility = "visible"
             }

            $("#Phrase"+i).GetChild(0).GetChild(0).text = $.Localize(rings[nowselect][0][i]);

            if (phase_deactive) {   
                var blocked = $.CreatePanel("Panel", $("#Phrase"+i).GetChild(0), "" );
                blocked.AddClass("BlockChatWheel");
                $("#Phrase"+i).GetChild(0).style.washColor = "red"
            }
        } else {
            let name = $.Localize("#chatwheel_birzha_null")
            var player_table = CustomNetTables.GetTableValue("birzhainfo", String(Players.GetLocalPlayer()))
            if (player_table)
            {
                if (player_table.chat_wheel)
                {
                    for (var itemType of itemTypes) 
                    {
                        for (var item of itemType) 
                        {
                            if (item[0] == String(player_table.chat_wheel[i + 1])) 
                            {
                                name = $.Localize("#" + item[4]);
                                break;
                            }
                        }
                    }    
                }
            }
            $("#Phrase"+i).GetChild(0).GetChild(0).text = name;
        }
    }
}

function StopWheel() {
    $("#Wheel").visible = false;
    $("#Bubble").visible = false;
    $("#PhrasesContainer").visible = false;
    $("#ChangeWheelButtons").visible = false;

    if (nowselect == 0)
    {
        var player_table = CustomNetTables.GetTableValue("birzhainfo", String(Players.GetLocalPlayer()))
        if (player_table)
        {
            if (player_table.chat_wheel)
            {
                if (player_table.chat_wheel[selected_sound_current+1])
                {
                    GameEvents.SendCustomGameEventToServer("SelectVO", {num: Number(player_table.chat_wheel[selected_sound_current+1])});
                }
            }
        }
    } else {
        var newnum = rings[nowselect][2][selected_sound_current];
        if (rings[nowselect][1][selected_sound_current])
        {
            GameEvents.SendCustomGameEventToServer("SelectVO", {num: Number(newnum)});
        }
    }
    selected_sound_current = undefined;
}

function OnMouseOver(num) {
    selected_sound_current = num;
    $( "#WheelPointer" ).RemoveClass( "Hidden" );
    $( "#Arrow" ).RemoveClass( "Hidden" );
    for ( var i = 0; i < 8; i++ )
    {
        if ($("#Wheel").BHasClass("ForWheel"+i))
            $( "#Wheel" ).RemoveClass( "ForWheel"+i );
    }
    $( "#Wheel" ).AddClass( "ForWheel"+num );
}

function OnMouseOut(num) {
    selected_sound_current = undefined;
    $( "#WheelPointer" ).AddClass( "Hidden" );
    $( "#Arrow" ).AddClass( "Hidden" );
}

const english_language_button = 
{
    "q" : "й",
    "w" : "ц",
    "e" : "у",
    "r" : "к",
    "t" : "е",
    "y" : "н",
    "u" : "г",
    "i" : "ш",
    "o" : "щ",
    "p" : "з",
    "a" : "ф",
    "s" : "ы",
    "d" : "в",
    "f" : "а",
    "g" : "п",
    "h" : "р",
    "j" : "о",
    "k" : "л",
    "l" : "д",
    "z" : "я",
    "x" : "ч",
    "c" : "с",
    "v" : "м",
    "b" : "и",
    "n" : "т",
    "m" : "ь",
}

const russian_language_button = 
{
    "й" : "q",
    "ц" : "w",
    "у" : "e",
    "к" : "r",
    "е" : "t",
    "н" : "y",
    "г" : "u",
    "ш" : "i",
    "щ" : "o",
    "з" : "p",
    "ф" : "a",
    "ы" : "s",
    "в" : "d",
    "а" : "f",
    "п" : "g",
    "р" : "h",
    "о" : "j",
    "л" : "k",
    "д" : "l",
    "я" : "z",
    "ч" : "x",
    "с" : "c",
    "м" : "v",
    "и" : "b",
    "т" : "n",
    "ь" : "m",
}
 
function SetKeyBindChatWheel()
{
    let original_keybind = GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_CHAT_WHEEL).toLowerCase()
    if (default_button != original_keybind ) 
    {
        if (original_keybind == "")
        {
            original_keybind = "Y"
        }
        original_keybind = original_keybind.toLowerCase()
        if (russian_language_button[original_keybind])
        {
            original_keybind = russian_language_button[original_keybind]
        }
        CreateKeyBind(original_keybind)
        if (english_language_button[original_keybind])
        {
            CreateKeyBind(english_language_button[original_keybind])  
        }
        default_button = original_keybind
        GameUI.CustomUIConfig().button_with_wheel = original_keybind.toUpperCase()
    } 
    $.Schedule( 1, SetKeyBindChatWheel );
}

function CreateKeyBind(key_name)
{
    const name_bind = "WheelButton" + Math.floor(Math.random() * 99999999);
    Game.AddCommand("+" + name_bind, StartWheel, "", 0);
    Game.AddCommand("-" + name_bind, StopWheel, "", 0);
    Game.CreateCustomKeyBind(key_name, "+" + name_bind);
} 

function GetGameKeybind(command) 
{
    return Game.GetKeybindForCommand(command);
}

(function() {
	GameUI.CustomUIConfig().chatWheelLoaded = true;
    SetKeyBindChatWheel()
    $("#Wheel").visible = false;
    $("#Bubble").visible = false;
    $("#PhrasesContainer").visible = false;
    $("#ChangeWheelButtons").visible = false;
})();