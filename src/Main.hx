import love.graphics.MeshDrawMode;
import love.graphics.Canvas;
import love.graphics.FilterMode;
import love.image.ImageFormat;
import love.image.ImageData;
import love.image.ImageModule;
import love.graphics.Image;
import love.math.MathModule;
import love.graphics.DrawMode;
import love.graphics.GraphicsModule;
import lua.Lua;
import love.Love;
import love.LoveProgram;
import love.filesystem.FilesystemModule;
import lua.Table;
import love.math.Transform;

using StringTools;

class Main extends LoveProgram {
	var time:Float = 0;
	var script:LoadResult;
	var scriptENV:Table<Dynamic, Dynamic> = Table.create();

	var drawFunction:Dynamic;
	var updateFunction:Dynamic;
	var update60Function:Dynamic;

	var initFuncRan:Bool = false;
	var hasInitedENV:Bool = false;
	var initFunction:Dynamic;

	var pallete:Array<Array<Int>> = [
		[0, 0, 0],
		[29, 42, 83],
		[126, 37, 83],
		[0, 135, 81],
		[171, 82, 54],
		[95, 87, 79],
		[194, 195, 199],
		[255, 241, 232],
		[255, 0, 77],
		[255, 163, 0],
		[255, 236, 39],
		[0, 228, 54],
		[41, 173, 255],
		[131, 118, 156],
		[255, 119, 168],
		[255, 204, 170, 255]
	];

	var palleteSwitches:Array<PalleteChange> = [];

	var spriteSheetImage:Image;

	var canvasForDrawing:Canvas;

	/**
		palette = {
			{ 0, 0, 0, 255 }, --        0: black
			{ 29, 43, 83, 255 }, --     1: dark-blue
			{ 126, 37, 83, 255 }, --    2: dark-purple
			{ 0, 135, 81, 255 }, --     3: dark-green
			{ 171, 82, 54, 255 }, --    4: brown
			{ 95, 87, 79, 255 }, --     5: dark-gray
			{ 194, 195, 199, 255 }, --  6: light-gray
			{ 255, 241, 232, 255 }, --  7: white
			{ 255, 0, 77, 255 }, --     8: red
			{ 255, 163, 0, 255 }, --    9: orange
			{ 255, 236, 39, 255 }, --  10: yellow
			{ 0, 228, 54, 255 }, --    11: green
			{ 41, 173, 255, 255 }, --  12: blue
			{ 131, 118, 156, 255 }, -- 13: indigo
			{ 255, 119, 168, 255 }, -- 14: pink
			{ 255, 204, 170, 255 }, -- 15: peach
	**/
	public static function main() {
		new Main();
	}

	function getTableValue(table:Table<Dynamic, Dynamic>, valueName:String) {
		var tblMap = Table.toMap(table);
		if (tblMap.exists(valueName)) {
			return tblMap.get(valueName);
		}
		return null;
	}

	override function load() {
		super.load();
		canvasForDrawing = GraphicsModule.newCanvas(128, 128);
		canvasForDrawing.setFilter(FilterMode.Nearest, FilterMode.Nearest);
		var _script = FilesystemModule.read("hello.p8");
		// trace(script);
		var thgng = splitFileIntoParts(_script.contents);
		trace(thgng.code);
		var spriteSheet:Array<Array<Int>> = [];
		var splittedSheet = thgng.gfx.split("\n");
		for (line in splittedSheet) {
			var lineee:Array<Int> = [];
			for (char in line.split("")) {
				lineee.push(Std.parseInt(char));
			}
			spriteSheet.push(lineee);
		}

		spriteSheet.remove(spriteSheet[0]);

		trace(spriteSheet.join(","));

		var heightSprSheet = spriteSheet.length;
		var widthSprSheet = spriteSheet[1].length;
		trace(widthSprSheet, heightSprSheet);
		var outtedSprite:ImageData = ImageModule.newImageData(widthSprSheet, heightSprSheet);

		var curY:Int = 1;
		var curX:Int = 1;
		for (line in spriteSheet) {
			curX = 1;
			trace(line);
			for (char in line) {
				if (char != null) {
					char = Std.int(Math.max(0, char));
					char = Std.int(Math.min(char, pallete.length));
					var colFromCol = pallete[char];
					if (colFromCol != null) {
						var r:Float = Math.max(Math.min((colFromCol[0] : Float) / 255, 1), 0.0);
						var g:Float = Math.max(Math.min((colFromCol[1] : Float) / 255, 1), 0.0);
						var b:Float = Math.max(Math.min((colFromCol[2] : Float) / 255, 1), 0.0);
						// var r = colFromCol[0];
						// var g = colFromCol[1];
						// var b = colFromCol[2];
						trace(r, g, b);
						trace(curX, curY);
						if (curX < widthSprSheet && curY < heightSprSheet && curX > 0 && curY > 0) {
							outtedSprite.setPixel(curX - 1, curY - 1, r, g, b, 255);
						}
					}
					curX += 1;
				}
			}
			curY += 1;
		}

		// outtedSprite.encode(ImageFormat.Png, "out.png");
		spriteSheetImage = GraphicsModule.newImage(outtedSprite);
		spriteSheetImage.setFilter(FilterMode.Nearest, FilterMode.Nearest);
		// trace(thgng.join("\n--[[       PART       ]]--\n"));

		script = Lua.load(thgng.code);
		while (script == null) {}
		if (script.message != null && script.message != "") {
			trace(script.message);
		}
		// while (script.func == null) {}
		// rScript.func();
	}

	function getColorPallete(col:Int) {
		if (col == null) {
			col = 0;
		}
		if (col == Math.NaN) {
			col = 0;
		}
		// trace(col);
		col = Std.int(Math.max(0, col));
		col = Std.int(Math.min(col, pallete.length - 1));
		for (palSwap in palleteSwitches) {
			if (palSwap.oColor == col) {
				col = palSwap.nColor;
			}
		}
		return pallete[col];
	}

	function setColToPalleteCol(col:Int) {
		var colFromCol = getColorPallete(col);
		if (colFromCol == null) {
			return;
		}
		GraphicsModule.setColor(colFromCol[0] / 255, colFromCol[1] / 255, colFromCol[2] / 255, 255 / 255);
	}

	function addFunctions(ENV:Table<Dynamic, Dynamic>) {
		ENV.music = function(i:Int) {
			trace("mus ran!");
		}
		ENV.spr = function(spr:Int, x:Float, y:Float) {
			var sprSheetXs = (spriteSheetImage.getWidth());
			var sprSheetYs = (spriteSheetImage.getHeight());
			var sprSheetX = (spr * 8) % sprSheetXs;
			var sprSheetY = Math.floor(spr / sprSheetYs) * 8;
			// setColToPalleteCol(0);
			// GraphicsModule.rectangle(DrawMode.Fill, x, y, 8, 8);
			// setColToPalleteCol(7);
			GraphicsModule.draw(cast spriteSheetImage, GraphicsModule.newQuad(sprSheetX, sprSheetY, 8, 8, spriteSheetImage), x, y);
			// setColToPalleteCol(4);

			// GraphicsModule.rectangle(DrawMode.Fill, x, y, 8, 8);
		}
		ENV.cls = function(col:Int) {
			if (col == null) {
				col = 0;
			}
			var colFromCol:Array<Int> = getColorPallete(col);
			col = Std.int(Math.max(0, col));
			col = Std.int(Math.min(col, pallete.length - 1));
			GraphicsModule.clear(colFromCol[0], colFromCol[1], colFromCol[2]);
		}
		ENV.t = function() {
			return time;
		}
		ENV.cos = function(value:Float) {
			return Math.cos(value * 6);
		}
		ENV.pal = function(t1:Int, t2:Int) {}
		ENV.print = function(str:String, x:Int, y:Int, col:Int) {}
		ENV.rnd = function(min:Int, max:Int) {
			return 0;
		}
		ENV.fillp = function(thing:Dynamic) {}
		ENV.rectfill = function(x:Float, y:Float, x2:Float, y2:Float, col:Int) {
			setColToPalleteCol(col);
			GraphicsModule.rectangle(DrawMode.Fill, x, y, x2, y2);
		}
		ENV.circfill = function(x:Float, y:Float, r:Float, col:Int) {
			setColToPalleteCol(col);
			GraphicsModule.circle(DrawMode.Fill, x, y, r);
		}
		ENV.sfx = function(id:Int) {}
		ENV.btnp = function(thing:String) {}
		/**function api.all(a)
			if a == nil then
				return function() end
			end

			local i = 0
			local len = #a
			return function()
				len = len - 1
				i = #a - len
				while a[i] == nil and len > 0 do
					len = len - 1
					i = #a - len
				end
				return a[i]
			end
			end**/
		ENV.all = function(fuckoff:Table<Int, Dynamic>):() -> Void {
			if (fuckoff == null) {
				return function() {}
			}

			var thingAsArray:Array<Dynamic> = cast Table.toArray(fuckoff);

			var i = 0;
			var len = thingAsArray.length;
			return function() {
				len = len - 1;
				i = thingAsArray.length - len;
				while (fuckoff[i] == null && len > 0) {
					len = len - 1;
					i = thingAsArray.length - len;
				}
				return thingAsArray[i];
			}

			return function() {}
		}
		ENV.add = function(tbl:Table<Int, Dynamic>, thing:Dynamic) {
			var tblAsArr = Table.toArray(tbl);
			tblAsArr.push(thing);
			tbl = Table.fromArray(tblAsArr);
			// return tbl;
		}
	}

	function getTab(stuff:String, toSplitBy:String) {
		if (stuff == "") {
			return "";
		}
		var splittedStuff = stuff.split(toSplitBy);
		if (splittedStuff.length > 1) {
			return splittedStuff[1];
		}
		return "";
	}

	function splitFileIntoParts(code:String):Pico8File {
		var realCode = getTab(code, "__lua__");
		var realGfx = getTab(realCode, "__gfx__");
		var realLabel = getTab(realGfx, "__label__");
		var realSfx = getTab(realGfx, "__sfx__");
		var realMusic = getTab(realGfx, "__music__");

		realCode = realCode.replace(realGfx, "");
		realGfx = realGfx.replace(realLabel, "");
		realLabel = realLabel.replace(realSfx, "");
		realSfx = realSfx.replace(realMusic, "");

		realCode = realCode.replace("__lua__", "");
		realCode = realCode.replace("__gfx__", "");
		realGfx = realGfx.replace("__label__", "");
		realLabel = realLabel.replace("__sfx__", "");
		realSfx = realSfx.replace("__music__", "");
		return new Pico8File(realCode, realGfx, realSfx, realLabel, realMusic);
	}

	override function draw() {
		super.draw();
		GraphicsModule.push();
		GraphicsModule.setCanvas(canvasForDrawing);
		if (drawFunction != null) {
			drawFunction();
			// setColToPalleteCol(7);
			var oColor = GraphicsModule.getColor();
			setColToPalleteCol(7);
			GraphicsModule.setColor(1, 1, 1, 1);
			GraphicsModule.draw(spriteSheetImage, 0, 0);
			// GraphicsModule.rectangle(DrawMode.Fill, 0, 0, 55, 55);
		}
		GraphicsModule.pop();
		GraphicsModule.scale(4, 4);
		GraphicsModule.setCanvas();
		GraphicsModule.draw(canvasForDrawing);
	}

	var shouldRunThisFrame = false;

	override function update(dt:Float) {
		super.update(dt);
		if (!hasInitedENV) {
			if (script.func != null) {
				Lua.setfenv(cast script.func, scriptENV);
				addFunctions(scriptENV);
				script.func();
				trace(scriptENV);
				drawFunction = getTableValue(scriptENV, "_draw");
				updateFunction = getTableValue(scriptENV, "_update");
				update60Function = getTableValue(scriptENV, "_update60");
				initFunction = getTableValue(scriptENV, "_init");
				if (initFunction != null) {
					initFunction();
				}
				hasInitedENV = true;
			}
			return;
		}
		time += dt;
		trace(time);
		/*if (initFunction != null) {
			if (!initFuncRan) {
				initFuncRan = true;
				initFunction();
			}
		}*/
		if (updateFunction != null && shouldRunThisFrame) {
			updateFunction();
		}
		if (update60Function != null) {
			update60Function();
		}
		shouldRunThisFrame = !shouldRunThisFrame;
	}
}

class Pico8File {
	public var code:String = "";
	public var gfx:String = "";
	public var sfx:String = "";
	public var label:String = "";
	public var music:String = "";

	public function new(code:String, gfx:String, sfx:String, label:String, music:String) {
		this.code = code;
		this.gfx = gfx;
		this.sfx = sfx;
		this.label = label;
		this.music = music;
	}
}

class PalleteChange {
	public var oColor:Int;
	public var nColor:Int;

	public function new(oColor:Int, nColor:Int) {
		this.oColor = oColor;
		this.nColor = nColor;
	}
}
