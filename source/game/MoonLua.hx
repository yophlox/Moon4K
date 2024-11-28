package game;

#if desktop
import llua.Lua;
import llua.LuaL;
import llua.State;
import flixel.FlxG;
import flixel.FlxSprite;
import states.PlayState;
import llua.Convert;
import game.Conductor;

class MoonLua {
    private var lua:State = null;
    private var scriptPath:String;
    private var game:PlayState;

    public function new(scriptPath:String) {
        this.scriptPath = scriptPath;
        this.game = PlayState.instance;
        
        lua = LuaL.newstate();
        LuaL.openlibs(lua);
        
        Lua_helper.register_hxtrace(lua);
        
        set_vars();
        
        set_callbacks();
        
        if (LuaL.dofile(lua, scriptPath) != 0) {
            var error = Lua.tostring(lua, -1);
            trace('Lua Error: $error');
            Lua.pop(lua, 1);
        }
    }

    private function set_vars() {
        // PlayState vars
        setVar("score", game.songScore);
        setVar("misses", game.misses);
        setVar("health", game.health);
        setVar("accuracy", game.accuracy);
        
        // Song info
        setVar("curBPM", Conductor.bpm);
        setVar("crochet", Conductor.crochet);
        setVar("stepCrochet", Conductor.stepCrochet);
        setVar("songPos", Conductor.songPosition);
        setVar("curStep", game.curStep);
        setVar("curBeat", game.curBeat);
    }

    private function set_callbacks() {
        addCallback("trace", function(text:Dynamic) {
            var traceText = Std.string(text);
            trace('Lua: $traceText');
        });
        
        addCallback("debugPrint", function(text:Dynamic) {
            var traceText = Std.string(text);
            trace('Lua Debug: $traceText');
        });
        
        addCallback("setScore", function(score:Int) {
            game.songScore = score;
        });
        
        addCallback("setHealth", function(health:Float) {
            game.health = health;
        });
        
        addCallback("getHealth", function():Float {
            return game.health;
        });
        
        addCallback("setCamZoom", function(zoom:Float) {
            FlxG.camera.zoom = zoom;
        });
        
        addCallback("getCamZoom", function():Float {
            return FlxG.camera.zoom;
        });
    }

    public function call(func:String, ?args:Array<Dynamic>):Dynamic {
        if (lua == null) return null;
        
        Lua.getglobal(lua, func);
        
        if (args != null) {
            for (arg in args) {
                Convert.toLua(lua, arg);
            }
        }
        
        var status = Lua.pcall(lua, args != null ? args.length : 0, 1, 0);
        if (status != 0) {
            var error = Lua.tostring(lua, -1);
            trace('Lua Error: $error');
            Lua.pop(lua, 1);
            return null;
        }
        
        var result = Convert.fromLua(lua, -1);
        Lua.pop(lua, 1);
        return result;
    }

    private function setVar(name:String, value:Dynamic) {
        Convert.toLua(lua, value);
        Lua.setglobal(lua, name);
    }

    private function addCallback(name:String, fn:Dynamic) {
        Lua_helper.add_callback(lua, name, fn);
    }

    public function destroy() {
        if (lua != null) {
            Lua.close(lua);
            lua = null;
        }
    }
}
#end
