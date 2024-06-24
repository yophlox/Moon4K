package;

import flixel.util.FlxSort;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	// Main 4k rhythm game sys
	var playerKeys:Array<Array<FlxKey>> = [[D], [SPACE], [J]];
	var strumlineArrows:FlxTypedGroup<FlxSprite>;
	var despawnNotes:FlxTypedGroup<FlxSprite>;
	var modellol:Flixel3D;
	var isRotating:Bool = false;
	var rotationTime:Float = 0;
	var rotationSpeed:Float = 2 * Math.PI / 2;
	var isMovingUpDown:Bool = false;
	var verticalMovementTime:Float = 0;
	var verticalSpeed:Float = 2.5;
	// so cools!

	override public function create()
	{
		FlxG.camera.bgColor = 0xFF333333;
		
		modellol = new Flixel3D();
		modellol.y = 150; 
		add(modellol);

		strumlineArrows = new FlxTypedGroup<FlxSprite>();
		add(strumlineArrows);

		despawnNotes = new FlxTypedGroup<FlxSprite>();
		add(despawnNotes);

		makeStrumline();

		super.create();

		despawnNotes.sort(FlxSort.byY);
	}

	override public function update(elapsed:Float)
	{
		for (i in 0...playerKeys.length) {
			keyCheck(i);
		}

		// Cool mechanic shits
		// TODO: Make a custom class for this shits

		// Rotating Notes (circle)
		if (FlxG.keys.justPressed.ONE)
		{
			isRotating = true;
		}
		
		// Up and down notes
		if (FlxG.keys.justPressed.TWO)
		{
			isMovingUpDown = true;
		}

		// Rotating Notes and Moving Up and Down
		if (FlxG.keys.justPressed.THREE)
		{
			isRotating = true;
			isMovingUpDown = true;
		}

		if (FlxG.keys.justPressed.R)
		{
			resetStrumlinePositions();
			isRotating = false;
			rotationTime = 0;
			isMovingUpDown = false;
			verticalMovementTime = 0;
		}

		if (isRotating)
		{
			rotationTime += elapsed;
			updateStrumlinePositions(rotationTime);
		}

		if (isMovingUpDown)
		{
			verticalMovementTime += elapsed;
			updateVerticalMovement(verticalMovementTime);
		}

		super.update(elapsed);
	}

	public function makeStrumline()
	{
		var arrowSpacing:Int = 120;
		var arrowWidth:Int = 112;
		var totalWidth:Int = (arrowSpacing * 2) + arrowWidth;
		var startX:Int = Std.int((FlxG.width - totalWidth) / 2);
		var yPos:Int = 50;

		for (i in 0...3) {
			var babyArrow:FlxSprite = new FlxSprite(startX + (arrowSpacing * i), yPos).makeGraphic(112, 112, 0xFF666666);
			babyArrow.alpha = 0.5;
			strumlineArrows.add(babyArrow);
		}
	}

	public function keyCheck(data:Int)
	{
		if (data < strumlineArrows.length && FlxG.keys.anyPressed(playerKeys[data])) {
			strumlineArrows.members[data].scale.set(0.95, 0.95);
		} else if (data < strumlineArrows.length) {
			strumlineArrows.members[data].scale.set(1, 1);
		}
	}

	public function updateStrumlinePositions(time:Float)
	{
		var centerX:Float = FlxG.width / 2;
		var centerY:Float = FlxG.height / 2;
		var radius:Float = 100;
		var angleIncrement:Float = 2 * Math.PI / strumlineArrows.length;

		for (i in 0...strumlineArrows.length)
		{
			var angle:Float = time * rotationSpeed + i * angleIncrement;
			var arrow:FlxSprite = strumlineArrows.members[i];
			arrow.x = centerX + radius * Math.cos(angle) - arrow.width / 2;
			arrow.y = centerY + radius * Math.sin(angle) - arrow.height / 2;
		}
	}

	public function updateVerticalMovement(time:Float)
	{
		var baseY:Float = FlxG.height / 2;
		var amplitude:Float = FlxG.height / 2;

		for (i in 0...strumlineArrows.length)
		{
			var arrow:FlxSprite = strumlineArrows.members[i];
			arrow.y = baseY + amplitude * Math.sin(verticalSpeed * time) - arrow.height / 2;
		}
	}

	public function resetStrumlinePositions()
	{
		var arrowSpacing:Int = 120;
		var arrowWidth:Int = 112;
		var totalWidth:Int = (arrowSpacing * 2) + arrowWidth;
		var startX:Int = Std.int((FlxG.width - totalWidth) / 2);
		var yPos:Int = 50;

		for (i in 0...strumlineArrows.length)
		{
			var arrow:FlxSprite = strumlineArrows.members[i];
			arrow.x = startX + (arrowSpacing * i);
			arrow.y = yPos;
		}
	}

	override function destroy()
	{
		super.destroy();
		modellol.destroy();
	}
}
