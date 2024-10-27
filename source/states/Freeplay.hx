package states;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import haxe.Json;
import lime.utils.Assets;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import game.HighScoreManager;
import util.Util;
import util.Cache;
#if desktop
import sys.FileSystem;
import sys.io.File;
#end
import flixel.graphics.FlxGraphic;
import util.stepmania.SMFile;
import util.stepmania.SMConverter;

using StringTools;

class Freeplay extends SwagState {
	var grpSongs:FlxTypedGroup<FlxText>;
	var songs:Array<String>;

	public var curSelected:Int = 0;

	var scoreText:FlxText;
	var missText:FlxText;
	var diffText:FlxText;

	public var selectedSong:String;

	static public var instance:Freeplay;

	var songData:Dynamic;

	public var songInfoData:Array<Dynamic>;

	var songHeight:Int = 100;
	var noSongsText:FlxText;

	var songImage:FlxSprite;

	public function new() {
		super();
		this.curSelected = 0;
		instance = this;
		loadSongs();
	}

	override public function create() {
		FlxG.stage.window.title = "Moon4K - FreeplayState";
		#if desktop
		Discord.changePresence("Selecting a song...", null);
		#end

		var coolBackdrop:FlxBackdrop = new FlxBackdrop(Paths.image('mainmenu/menubglol'), XY, 0.2, 0);
		coolBackdrop.velocity.set(50, 30);
		coolBackdrop.alpha = 0.7;
		add(coolBackdrop);

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		var leText:String = "Press R to scan the songs folder.";
		var size:Int = 18;
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		super.create();

		grpSongs = new FlxTypedGroup<FlxText>();
		add(grpSongs);

		songImage = new FlxSprite(FlxG.width * 0.5, 100);
		songImage.makeGraphic(500, 300, FlxColor.BLACK);
		add(songImage);

		updateSongList();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, RIGHT);

		missText = new FlxText(FlxG.width * 0.7, 40, 0, "", 32);
		missText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, RIGHT);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);
		add(scoreText);
		add(missText);

		changeSelection();
		super.create();
	}

	override public function update(elapsed:Float) {
		var highScoreData = HighScoreManager.getHighScoreForSong(selectedSong);
		scoreText.text = "SCORE: " + highScoreData.score;
		missText.text = "MISSES: " + highScoreData.misses;

		if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE) {
			transitionState(new states.MainMenuState());
		}

		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN) {
			changeSelection(FlxG.keys.justPressed.UP ? -1 : 1);
			updateSongImage();
		}

		if (FlxG.keys.justPressed.ENTER) {
			FlxG.sound.music.stop();
			loadSongJson(selectedSong);
			transitionState(new PlayState());
			PlayState.instance.song = songData;
		}

		if (FlxG.keys.justPressed.R) {
			rescanSongs();
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		var startY:Int = 50;
		var spacing:Int = 100;

		var offsetY:Float = Math.max(0, (curSelected * spacing) - (FlxG.height / 2) + (spacing / 2));

		grpSongs.forEach((txt:FlxText) -> {
			txt.y = startY + (txt.ID * spacing) - offsetY;
			txt.color = FlxColor.WHITE;
			txt.x = 20;
			txt.alignment = FlxTextAlign.LEFT;

			if (txt.ID == curSelected) {
				txt.size = 36;
				txt.alpha = 1.0;
			} else {
				txt.size = 32;
				txt.alpha = 0.7;
			}
		});

		selectedSong = songs[curSelected];
		updateSongImage();
	}

	function updateSongImage():Void {
		var imagePath = '${selectedSong}/image';
		trace('Attempting to load image: $imagePath');

		var loadedImage:FlxGraphic = Cache.getFromCache(imagePath, "image");
		if (loadedImage == null) {
			loadedImage = Util.getchartImage(imagePath);
			if (loadedImage != null) {
				Cache.addToCache(imagePath, loadedImage, "image");
				trace('Successfully loaded and cached image: $imagePath');
			} else {
				trace('Image not found: $imagePath');
			}
		} else {
			trace('Using cached image: $imagePath');
		}

		if (loadedImage != null) {
			songImage.loadGraphic(loadedImage);
		} else {
			songImage.makeGraphic(400, 300, FlxColor.BLACK);
		}

		songImage.setGraphicSize(400, 300);
		songImage.updateHitbox();
		songImage.screenCenter(Y);
		songImage.x = FlxG.width * 0.5;
	}

	function loadSongJson(songName:String):Void {
		var cleanSongName = songName.toLowerCase().replace(" ", "").replace("(", "").replace(")", "");
		var path = "assets/charts/" + songName + "/" + cleanSongName;
		
		var moonPath = path + ".moon";
		if (FileSystem.exists(moonPath)) {
			var jsonContent:String = File.getContent(moonPath);
			songData = Json.parse(jsonContent);
			trace("Loaded Moon format: " + moonPath);
		} else {
			var directory = "assets/charts/" + songName;
			var files = FileSystem.readDirectory(directory);
			var foundFile:String = null;
			
			for (f in files) {
				var lowerFile = f.toLowerCase().replace(" ", "").replace("(", "").replace(")", "");
				var lowerSong = cleanSongName;
				if (lowerFile == lowerSong + ".sm" || lowerFile == lowerSong + ".ssc") {
					foundFile = f;
					break;
				}
			}
			
			if (foundFile != null) {
				var fullPath = directory + "/" + foundFile;
				var smContent:String = File.getContent(fullPath);
				var smFile = new SMFile(smContent);
				songData = SMConverter.convertToMoonFormat(smFile);
				trace("Loaded and converted StepMania format: " + fullPath);
			} else {
				trace("No compatible chart found for: " + songName);
				songData = null;
			}
		}

		if (songData != null) {
			songData.song = songName;
		}
	}

	function loadSongs():Void {
		songs = [];
		var dataDir:String = "assets/charts/";
		#if web
		songs = ["bopeebo"];
		#else
		var directories:Array<String> = FileSystem.readDirectory(dataDir);
		for (dir in directories) {
			var fullPath:String = dataDir + dir;
			if (FileSystem.isDirectory(fullPath)) {
				songs.push(dir);
			}
		}
		#end
	}

	function updateSongList():Void {
		grpSongs.clear();
		loadSongs();

		if (songs.length == 0) {
			if (noSongsText == null) {
				noSongsText = new FlxText(0, FlxG.height / 2 - 10, FlxG.width, "There's no songs in the songs folder!", 24);
				noSongsText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.RED, CENTER);
				add(noSongsText);
			}
		} else {
			if (noSongsText != null) {
				remove(noSongsText);
				noSongsText = null;
			}
			for (i in 0...songs.length) {
				var songTxt:FlxText = new FlxText(20, 50 + (i * songHeight), FlxG.width * 0.6, songs[i], 32);
				songTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
				songTxt.scrollFactor.set();
				songTxt.ID = i;
				grpSongs.add(songTxt);
			}
			selectedSong = songs[curSelected];
			updateSongImage();
		}
	}

	function rescanSongs():Void {
		updateSongList();
		changeSelection();
	}
}
