import love.graphics.Texture;
import love.graphics.Shader;
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

	var shader:Shader;

	var pallete:Array<Array<Int>> = [
		[0, 0, 0, 255], //        0: black
		[29, 43, 83, 255], //     1: dark-blue
		[126, 37, 83, 255], //    2: dark-purple
		[0, 135, 81, 255], //     3: dark-green
		[171, 82, 54, 255], //    4: brown
		[95, 87, 79, 255], //     5: dark-gray
		[194, 195, 199, 255], //  6: light-gray
		[255, 241, 232, 255], //  7: white
		[255, 0, 77, 255], //     8: red
		[255, 163, 0, 255], //    9: orange
		[255, 236, 39, 255], //  10: yellow
		[0, 228, 54, 255], //    11: green
		[41, 173, 255, 255], //  12: blue
		[131, 118, 156, 255], // 13: indigo
		[255, 119, 168, 255], // 14: pink
		[255, 204, 170, 255], // 15: peach
		[0, 0, 0, 0] //          16: clear
	];

	var palleteSwitches:Array<PalleteChange> = [];

	var spriteSheetImage:Image;
	var fontImage:Image;
	var fontMapping:Map<String, Array<Int>> = [
		"-" => [100, 11, 5, 5, 0, 1],
		"_" => [68, 11, 5, 5, 0, 0],
		"a" => [0, 0],
		"b" => [4, 0],
		"c" => [8, 0],
		"d" => [12, 0],
		"e" => [16, 0],
		"f" => [20, 0],
		"g" => [24, 0],
		"h" => [28, 0],
		"i" => [32, 0],
		"j" => [36, 0],
		"k" => [40, 0],
		"l" => [44, 0],
		"m" => [48, 0],
		"n" => [52, 0],
		"o" => [56, 0],
		"p" => [60, 0],
		"q" => [64, 0],
		"r" => [68, 0],
		"s" => [72, 0],
		"t" => [76, 0],
		"u" => [80, 0],
		"v" => [84, 0],
		"w" => [88, 0],
		"x" => [92, 0],
		"y" => [96, 0],
		"z" => [100, 0],
		"A" => [0, 7, 5, 4, 0, 2],
		"B" => [4, 7, 5, 4, 0, 2],
		"C" => [8, 7, 5, 4, 0, 2],
		"D" => [12, 7, 5, 4, 0, 2],
		"E" => [16, 7, 5, 4, 0, 2],
		"F" => [20, 7, 5, 4, 0, 2],
		"G" => [24, 7, 5, 4, 0, 2],
		"H" => [28, 7, 5, 4, 0, 2],
		"I" => [32, 7, 5, 4, 0, 2],
		"J" => [36, 7, 5, 4, 0, 2],
		"K" => [40, 7, 5, 4, 0, 2],
		"L" => [44, 7, 5, 4, 0, 2],
		"M" => [48, 7, 5, 4, 0, 2],
		"N" => [52, 7, 5, 4, 0, 2],
		"O" => [56, 7, 5, 4, 0, 2],
		"P" => [60, 7, 5, 4, 0, 2],
		"Q" => [64, 7, 5, 4, 0, 2],
		"R" => [68, 7, 5, 4, 0, 2],
		"S" => [72, 7, 5, 4, 0, 2],
		"T" => [76, 7, 5, 4, 0, 2],
		"U" => [80, 7, 5, 4, 0, 2],
		"V" => [84, 7, 5, 4, 0, 2],
		"W" => [88, 7, 5, 4, 0, 2],
		"X" => [92, 7, 5, 4, 0, 2],
		"Y" => [96, 7, 5, 4, 0, 2],
		"Z" => [100, 7, 5, 4, 0, 2],
		"0" => [0, 11, 4, 5],
		"1" => [4, 11, 4, 5],
		"2" => [8, 11, 4, 5],
		"3" => [12, 11, 4, 5],
		"4" => [16, 11, 4, 5],
		"5" => [20, 11, 4, 5],
		"6" => [24, 11, 4, 5],
		"7" => [28, 11, 4, 5],
		"8" => [32, 11, 4, 5],
		"9" => [36, 11, 4, 5],
		"." => [40, 11, 3, 5]
	];

	var canvasForDrawing:Canvas;

	var defaultColorPalleteIndices:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
	var currentColorPalleteIndices:Array<Int> = [];

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
		currentColorPalleteIndices = defaultColorPalleteIndices;
		canvasForDrawing = GraphicsModule.newCanvas(128, 128);
		fontImage = GraphicsModule.newImage("font.png");
		shader = GraphicsModule.newShader("
			extern int colorPalleteIndexes[17];
			extern vec4 colorPallete[17];

			vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
				vec4 _px = Texel(texture, texture_coords); // This is the current pixel color
				number indx = (_px.r*255);
				vec4 pixel = colorPallete[colorPalleteIndexes[int(indx)]];
				//pixel.r = pixel.r / 255;
				//pixel.g = pixel.g / 255;
				//pixel.b = pixel.b / 255;
				//pixel.a = 1 - pixel.a;
				//pixel.a = 1;
				return pixel;
			}
		");
		// trace(unpackBChaxedontgotit(Table.fromArray(pallete)));
		var tblOfTables:Table<Int, Table<Int, Float>> = Table.create();
		for (col in pallete) {
			var ttlbl:Table<Int, Float> = Table.create();
			for (num in col) {
				Table.insert(ttlbl, num / 255);
			}
			Table.insert(tblOfTables, ttlbl);
		}
		shader.send("colorPallete", unpackBChaxedontgotit(tblOfTables));
		shader.send("colorPalleteIndexes", unpackBChaxedontgotit(defaultColorPalleteIndices));
		canvasForDrawing.setFilter(FilterMode.Nearest, FilterMode.Nearest);
		var _script = FilesystemModule.read("hello.p8");
		// trace(script);
		var thgng = splitFileIntoParts(_script.contents);
		// trace(thgng.code);
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

		// trace(spriteSheet.join(","));

		var heightSprSheet = spriteSheet.length;
		var widthSprSheet = spriteSheet[1].length;
		// trace(widthSprSheet, heightSprSheet);
		var outtedSprite:ImageData = ImageModule.newImageData(widthSprSheet, heightSprSheet);

		var curY:Int = 1;
		var curX:Int = 1;
		for (line in spriteSheet) {
			curX = 1;
			// trace(line);
			for (char in line) {
				if (char != null) {
					char = Std.int(Math.max(0, char));
					char = Std.int(Math.min(char, pallete.length));
					if (char != null) {
						// var r:Float = Math.max(Math.min((colFromCol[0] : Float) / 255, 1), 0.0);
						// var g:Float = Math.max(Math.min((colFromCol[1] : Float) / 255, 1), 0.0);
						// var b:Float = Math.max(Math.min((colFromCol[2] : Float) / 255, 1), 0.0);
						// var r = colFromCol[0];
						// var g = colFromCol[1];
						// var b = colFromCol[2];
						// trace(r, g, b);
						// trace(curX, curY);
						if (curX < widthSprSheet && curY < heightSprSheet && curX > 0 && curY > 0) {
							outtedSprite.setPixel(curX - 1, curY - 1, char / 255, char / 255, char / 255, char / 255);
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
		col = currentColorPalleteIndices[col];
		// trace(col);
		col = Std.int(Math.max(0, col));
		col = Std.int(Math.min(col, pallete.length - 1));
		/*for (palSwap in palleteSwitches) {
				if (palSwap.oColor == col) {
					col = palSwap.nColor;
				}
			}
			return pallete[col]; */
		return [col, col, col];
	}

	function setColToPalleteCol(col:Int) {
		var colFromCol = getColorPallete(col);
		if (colFromCol == null) {
			return;
		}
		GraphicsModule.setColor(colFromCol[0], colFromCol[1], colFromCol[2], 255 / 255);
	}

	function unpackBChaxedontgotit(thing:Dynamic) {
		return untyped __lua__("unpack({0})", thing);
	}

	function pal(toEdit:Int, toChangeTo:Int) {
		currentColorPalleteIndices[toEdit] = defaultColorPalleteIndices[toChangeTo];
		shader.send("colorPalleteIndexes", unpackBChaxedontgotit(Table.fromArray(currentColorPalleteIndices)));
	}

	var lastTextColor:Int = -1;
	var lastTextPosition:Array<Int> = [];

	function addFunctions(ENV:Table<Dynamic, Dynamic>) {
		ENV.music = function(i:Int) {
			// trace("mus ran!");
		}
		ENV.spr = function(spr:Int, x:Float, y:Float) {
			// GraphicsModule.setShader(shader);
			var sprSheetXs = (spriteSheetImage.getWidth());
			var sprSheetYs = (spriteSheetImage.getHeight());
			var sprSheetX = (spr * 8) % sprSheetXs;
			var sprSheetY = Math.floor(spr / sprSheetYs) * 8;
			setColToPalleteCol(7);
			// GraphicsModule.rectangle(DrawMode.Fill, x, y, 8, 8);
			// GraphicsModule.setShader(shader);
			GraphicsModule.draw(cast spriteSheetImage, GraphicsModule.newQuad(sprSheetX, sprSheetY, 8, 8, spriteSheetImage), x, y);
			// GraphicsModule.setShader();
			// setColToPalleteCol(4);
		}
		/*ENV.print = function(text:String, x:Float, y:Float, col:Int) {
			for (letter in text) {
				// GraphicsModule.draw(cast fontImage, GraphicsModule.newQuad());
			}
			// GraphicsModule.draw(cast fontImage, GraphicsModule.newQuad());
		}*/
		ENV.cls = function(col:Int) {
			if (col == null) {
				col = 0;
			}
			var colFromCol:Array<Int> = getColorPallete(col);
			col = Std.int(Math.max(0, col));
			col = Std.int(Math.min(col, pallete.length - 1));
			GraphicsModule.clear(colFromCol[0], colFromCol[1], colFromCol[2]);
			pal(col, 16);
		}
		ENV.t = function() {
			return Math.round(time * 400) / 400;
			// return Math.round(time, 2);
		}
		ENV.cos = function(value:Float) {
			return Math.cos(value * 6);
		}
		ENV.pal = function(toEdit:Int, toChangeTo:Int) {
			pal(toEdit, toChangeTo);
		}
		ENV.tostr = function(thing:Dynamic) {
			return Lua.tostring(thing);
		}
		ENV.print = function(strValue:Dynamic, x:Int, y:Int, col:Int) {
			var str:String = Lua.tostring(strValue);
			if (x == null && y == null && lastTextPosition != null && lastTextPosition.length > 1) {
				x = lastTextPosition[0];
				y = lastTextPosition[1] + 7;
			} else {
				if (x == null) {
					x = 0;
				}
				if (y == null) {
					y = 0;
				}
			}
			if (col == null) {
				if (lastTextColor != null && lastTextColor != -1) {
					col = lastTextColor;
				} else {
					col = 7;
				}
			}
			var i:Int = 0;
			var oColorAt7 = currentColorPalleteIndices[6];
			pal(7, col);
			for (letter in str.split("")) {
				// trace(letter);
				if (fontMapping.exists(letter)) {
					/*if (letter == "-") {
						trace("fuckin wanker");
					}*/
					var letterPositioning:Array<Int> = fontMapping.get(letter);
					var charWidth:Int = 5;
					var charHeight:Int = 7;
					var xOffset:Int = 0;
					var yOffset:Int = 0;
					if (letterPositioning[2] != null) {
						charHeight = letterPositioning[2];
					}
					if (letterPositioning[3] != null) {
						charHeight = letterPositioning[3];
					}
					if (letterPositioning[4] != null) {
						xOffset = letterPositioning[4];
					}
					if (letterPositioning[5] != null) {
						yOffset = letterPositioning[5];
					}
					GraphicsModule.draw(cast fontImage, GraphicsModule.newQuad(letterPositioning[0], letterPositioning[1], charWidth, charHeight, fontImage),
						x
						+ (i * 4)
						+ xOffset, y
						+ yOffset);
				}
				i++;
			}
			pal(7, oColorAt7);
			lastTextPosition = [x, y];
			lastTextColor = col;
		}
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

	var shouldRunThisFrame = false;

	override function draw() {
		super.draw();
		lastTextPosition = [];
		lastTextColor = -1;
		currentColorPalleteIndices = defaultColorPalleteIndices.copy();
		GraphicsModule.setColor(1, 1, 1, 1);
		GraphicsModule.push();
		GraphicsModule.setShader(shader);
		// GraphicsModule.setShader(shader);
		GraphicsModule.setCanvas(canvasForDrawing);
		if (drawFunction != null && shouldRunThisFrame) {
			drawFunction();
			// setColToPalleteCol(7);
			setColToPalleteCol(7);
			// GraphicsModule.setColor(1, 1, 1, 1);
			// GraphicsModule.draw(spriteSheetImage, 0, 0);
			// GraphicsModule.rectangle(DrawMode.Fill, 0, 0, 55, 55);
			// GraphicsModule.draw(spriteSheetImage, 0, 0);
		}
		// GraphicsModule.setShader();
		GraphicsModule.setShader();
		GraphicsModule.pop();
		GraphicsModule.scale(4, 4);
		GraphicsModule.setCanvas();
		GraphicsModule.draw(canvasForDrawing);
	}

	override function update(dt:Float) {
		super.update(dt);
		if (!hasInitedENV) {
			if (script.func != null) {
				Lua.setfenv(cast script.func, scriptENV);
				addFunctions(scriptENV);
				script.func();
				// trace(scriptENV);
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
		// trace(time);
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
