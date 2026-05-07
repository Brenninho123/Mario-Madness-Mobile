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
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.system.System;
import lime.system.System as LimeSystem;

#if mobile
import mobile.backend.MobileScaleMode;
#if android
import mobile.backend.StorageUtil;
#end
#end

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

class Main extends Sprite
{
	public static var initialState:Class<FlxState> = TitleState;
	public static var gameWidth:Int  = 1280;
	public static var gameHeight:Int = 720;

	var zoom:Float       = -1;
	var framerate:Int    = 60;
	var skipSplash:Bool  = true;
	var startFullscreen:Bool = false;

	public static var fpsVar:FPS;

	public static var skipNextDump:Bool      = false;
	public static var forceNoVramSprites:Bool = #if (desktop && !web) false #else true #end;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		#if android
		StorageUtil.requestPermissions();
		#end

		#if mobile
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?e:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	public function setupGame():Void
	{
		Lib.application.window.onClose.add(PlayState.onWinClose);

		#if !debug
		initialState = TitleState;
		#end

		FlxTransitionableState.skipNextTransOut = true;

		#if !mobile
		fpsVar = new FPS(10, 4, 0xFFFFFF);
		if (fpsVar != null) fpsVar.visible = false;
		#end

		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));

		Lib.current.stage.align     = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		#if mobile
		LimeSystem.allowScreenTimeout = false;
		FlxG.scaleMode = new MobileScaleMode();
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if html5
		FlxG.autoPause     = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.signals.preStateSwitch.add(function()
		{
			if (!Main.skipNextDump)
			{
				Paths.clearStoredMemory(true);
				FlxG.bitmap.dumpCache();
			}
			clearMajor();
		});

		FlxG.signals.postStateSwitch.add(function()
		{
			Paths.clearUnusedMemory();
			clearMajor();
			Main.skipNextDump = false;
		});

		#if !mobile
		addChild(fpsVar);
		#end

		_setupFocusHandlers();

		FlxG.signals.gameResized.add(onResizeGame);
	}

	function _setupFocusHandlers():Void
	{
		Lib.current.stage.addEventListener(FocusEvent.FOCUS_IN, function(_)
		{
			#if mobile
			LimeSystem.allowScreenTimeout = false;
			#end
			FlxG.game.focusLostFramerate = framerate;
		});

		Lib.current.stage.addEventListener(FocusEvent.FOCUS_OUT, function(_)
		{
			#if mobile
			LimeSystem.allowScreenTimeout = true;
			#end
			FlxG.game.focusLostFramerate = 10;
		});
	}

	function onResizeGame(w:Int, h:Int):Void
	{
		fixShaderSize(this);
		if (FlxG.game != null) fixShaderSize(FlxG.game);
		if (FlxG.cameras == null) return;

		for (cam in FlxG.cameras.list)
		{
			@:privateAccess
			if (cam != null && cam._filters != null)
				fixShaderSize(cam.flashSprite);
		}
	}

	function fixShaderSize(sprite:Sprite):Void
	{
		if (sprite == null) return;
		@:privateAccess
		{
			sprite.__cacheBitmap              = null;
			sprite.__cacheBitmapData          = null;
			sprite.__cacheBitmapData2         = null;
			sprite.__cacheBitmapData3         = null;
			sprite.__cacheBitmapColorTransform = null;
		}
	}

	public static function clearMajor():Void
	{
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
