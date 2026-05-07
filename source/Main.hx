package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.system.System;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

class Main extends Sprite {
	public static var initialState:Class<FlxState> = TitleState;
	public static var gameWidth:Int = 1280; 
	public static var gameHeight:Int = 720;
	var zoom:Float = -1;
	var framerate:Int = 60;
	var skipSplash:Bool = true;
	var startFullscreen:Bool = false;

	public static var fpsVar:FPS;
	public static var skipNextDump:Bool = false;
	public static var forceNoVramSprites:Bool = #if mobile true #else false #end;

	public static function main():Void {
		Lib.current.addChild(new Main());
	}

	public function new() {
		super();

		if (stage != null) {
			init();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE)) {
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	public function setupGame():Void {
		#if mobile
		FlxG.signals.gameResized.add(function(w:Int, h:Int) {
			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null)
						fixShaderSize(cam.flashSprite);
				}
			}
		});
		#end

		Lib.application.window.onClose.add(PlayState.onWinClose);

		#if !debug
		initialState = TitleState;
		#end

		FlxTransitionableState.skipNextTransOut = true;

		var game = new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen);
		addChild(game);

		#if !mobile
		fpsVar = new FPS(10, 4, 0xFFFFFF);
		addChild(fpsVar);
		#end

		FlxG.signals.preStateSwitch.add(function() {
			if (!Main.skipNextDump) {
				Paths.clearStoredMemory(true);
				FlxG.bitmap.dumpCache();
			}
			clearMajor();
		});

		FlxG.signals.postStateSwitch.add(function() {
			Paths.clearUnusedMemory();
			clearMajor();
			Main.skipNextDump = false;
		});

		#if html5
		FlxG.autoPause = false;
		#end
		
		#if mobile
		FlxG.mouse.visible = false;
		#end
	}

	function fixShaderSize(sprite:Sprite) {
		@:privateAccess {
			if (sprite != null) {
				sprite.__cacheBitmap = null;
				sprite.__cacheBitmapData = null;
				sprite.__cacheBitmapData2 = null;
				sprite.__cacheBitmapData3 = null;
				sprite.__cacheBitmapColorTransform = null;
			}
		}
	}

	public static function clearMajor() {
		#if cpp
		Gc.run(true);
		Gc.compact();
		#elseif hl
		Gc.major();
		#elseif (java || neko)
		Gc.run(true);
		#end
	}
}
