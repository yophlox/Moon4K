package states;

import states.SwagState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import options.Controls;
import options.Options;
import substates.BaseOptionsSubState;
import util.Util;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxMath;

class OptionSelectState extends SwagState
{
    var curSelected:Int = 0;

    var camFollow:FlxObject;
    var camFollowPos:FlxObject;

    var menuShit:Array<Dynamic> = [
        ["Graphics", "Change how the game looks!"],
        ["Gameplay", "Change stuff to help your gameplay!"],
        ["Controls", "Change your controls. See what fits you best!"],
        ["Exit", "Exit the options menu."]
    ];
    var menuItems:FlxTypedGroup<OptionSelectBox>;

    override public function create()
    {
        FlxG.stage.window.title = "YA4KRG Demo - OptionsState";

        super.create();

        var coolBackdrop:FlxBackdrop = new FlxBackdrop(Paths.image('menubglol'), 0.2, 0, true, true);
        coolBackdrop.velocity.set(50, 30);
        coolBackdrop.alpha = 0.7;
        add(coolBackdrop);

        menuItems = new FlxTypedGroup<OptionSelectBox>();
        add(menuItems);

        for (i in 0...menuShit.length)
        {
            var option:OptionSelectBox = new OptionSelectBox(0, (100 * i), menuShit[i][0], menuShit[i][1]);
            menuItems.add(option);
        }

        camFollow = new FlxObject(0, 0, 1, 1);
        changeSelection();
        camFollowPos = new FlxObject(camFollow.x, camFollow.y, 1, 1);
        add(camFollow);
        add(camFollowPos);

        FlxG.camera.follow(camFollowPos, null, 1);
    }

    override public function closeSubState()
    {
        super.closeSubState();

        persistentDraw = true;
        FlxG.camera.follow(camFollowPos, null, 1);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        FlxG.camera.follow(camFollowPos, null, 1);

        var lerpVal:Float = Util.boundTo(elapsed * 5.6, 0, 1);
        camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

        if (Controls.BACK)
            transitionState(new SplashState());

        if (Controls.UI_UP)
            changeSelection(-1);

        if (Controls.UI_DOWN)
            changeSelection(1);

        if (Controls.ACCEPT)
        {
            switch (menuShit[curSelected][0])
            {
                case 'Graphics':
                    // "title", "desc", "save", "type", []
                    BaseOptionsSubState.menuShit = [
                        [
                            "Anti-Aliasing",
                            "Improves performance at the cost of sharper graphics when\ndisabled.",
                            "antialiasing",
                            "bool"
                        ],
                        [   "UI Skin",
                            "Select skins for Notes", 
                            "ui-skin",
                            "menu"
                        ]
                    ];

                    persistentDraw = false;
                    openSubState(new BaseOptionsSubState());
                case 'Gameplay':
                    // "title", "desc", "save", "type", []
                    BaseOptionsSubState.menuShit = [
                        [
                            "Downscroll",
                            "Makes all notes scroll downwards instead of upwards.",
                            "downscroll",
                            "bool"
                        ],
                        [
                            "Note Offset",
                            "Adjust how early/late your notes appear on-screen.",
                            "note-offset",
                            "float",
                            [-1000, 1000],
                            0.1
                        ]
                    ];

                    persistentDraw = false;
                    openSubState(new BaseOptionsSubState());
                case 'Exit':
                    transitionState(new SplashState());
            }
        }
    }

    function changeSelection(?change:Int = 0)
    {
        curSelected += change;

        if (curSelected < 0)
            curSelected = menuItems.members.length - 1;

        if (curSelected > menuItems.members.length - 1)
            curSelected = 0;

        for (i in 0...menuItems.members.length)
        {
            var optionBox = menuItems.members[i];
            for (text in optionBox.members)
            {
                if (Std.is(text, FlxText))
                {
                    var flxText = cast text;
                    flxText.color = (curSelected == i) ? FlxColor.YELLOW : FlxColor.WHITE;
                }
            }
        }

        camFollow.setPosition(menuItems.members[curSelected].members[0].getGraphicMidpoint().x,
            menuItems.members[curSelected].members[0].getGraphicMidpoint().y);
    }
}

class OptionSelectBox extends FlxTypedGroup<FlxText>
{
    public function new(x:Float, y:Float, title:String, desc:String)
    {
        super();

        var titleText:FlxText = new FlxText(x, y, 0, title, 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
        titleText.screenCenter(X);
        titleText.antialiasing = Options.getData('antialiasing');
        add(titleText);

        var descText:FlxText = new FlxText(x, y + 50, 0, desc, 24);
        descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
        descText.screenCenter(X);
        descText.antialiasing = Options.getData('antialiasing');
        add(descText);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
