package;

import flash.media.Sound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import haxe.Json;
import haxe.xml.Access;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> = [
		'characters', 'custom_events', 'custom_notetypes', 'data', 'songs',
		'music', 'sounds', 'shaders', 'videos', 'images', 'stages',
		'weeks', 'fonts', 'scripts', 'achievements'
	];
	#end

	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static function clearUnusedMemory() {
		for (key in currentTrackedAssets.keys()) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)) {
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		System.gc();
	}

	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys()) {
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key)) {
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;

	static public function setCurrentLevel(name:String) {
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null) {
		if (library != null) return getLibraryPath(file, library);

		if (currentLevel != null) {
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type)) return levelPath;
			}
			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type)) return levelPath;
		}
		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload") {
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String) {
		return '$library:assets/$library/$file';
	}

	inline public static function getPreloadPath(file:String = '') {
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String) return getPath(file, type, library);
	inline static public function txt(key:String, ?library:String) return getPath('data/$key.txt', TEXT, library);
	inline static public function xml(key:String, ?library:String) return getPath('data/$key.xml', TEXT, library);
	inline static public function json(key:String, ?library:String) return getPath('data/$key.json', TEXT, library);
	inline static public function shaderFragment(key:String, ?library:String) return getPath('shaders/$key.frag', TEXT, library);
	inline static public function shaderVertex(key:String, ?library:String) return getPath('shaders/$key.vert', TEXT, library);
	inline static public function lua(key:String, ?library:String) return getPath('$key.lua', TEXT, library);

	static public function video(key:String) {
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound return returnSound('sounds', key, library);
	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String) return sound(key + FlxG.random.int(min, max), library);
	inline static public function music(key:String, ?library:String):Sound return returnSound('music', key, library);

	inline static public function voices(song:String):Any {
		var songKey:String = '${formatToSongPath(song)}/Voices';
		return returnSound('songs', songKey);
	}

	inline static public function inst(song:String):Any {
		var songKey:String = '${formatToSongPath(song)}/Inst';
		return returnSound('songs', songKey);
	}

	inline static public function image(key:String, ?library:String):FlxGraphic return returnGraphic(key, library);

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String {
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key))) return File.getContent(modFolders(key));
		#end
		if (FileSystem.exists(getPreloadPath(key))) return File.getContent(getPreloadPath(key));
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String) {
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String) {
		#if MODS_ALLOWED
		if(FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key))) return true;
		#end
		return OpenFlAssets.exists(getPath(key, type));
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames {
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = FileSystem.exists(modsXml(key));
		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String) {
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = FileSystem.exists(modsTxt(key));
		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;
		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String) {
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);
		if(FileSystem.exists(modKey)) {
			if(!currentTrackedAssets.exists(modKey)) {
				var newBitmap:BitmapData = BitmapData.fromFile(modKey);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, modKey);
				newGraphic.persist = true;
				currentTrackedAssets.set(modKey, newGraphic);
			}
			localTrackedAssets.push(modKey);
			return currentTrackedAssets.get(modKey);
		}
		#end

		var path = getPath('images/$key.png', IMAGE, library);
		if (OpenFlAssets.exists(path, IMAGE)) {
			if(!currentTrackedAssets.exists(path)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file)) currentTrackedSounds.set(file, Sound.fromFile(file));
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end

		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		
		if(!currentTrackedSounds.exists(gottenPath)) {
			var folder:String = (path == 'songs') ? 'songs:' : '';
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '') return 'mods/' + key;
	inline static public function modsFont(key:String) return modFolders('fonts/' + key);
	inline static public function modsJson(key:String) return modFolders('data/' + key + '.json');
	inline static public function modsVideo(key:String) return modFolders('videos/' + key + '.' + VIDEO_EXT);
	inline static public function modsSounds(path:String, key:String) return modFolders(path + '/' + key + '.' + SOUND_EXT);
	inline static public function modsImages(key:String) return modFolders('images/' + key + '.png');
	inline static public function modsXml(key:String) return modFolders('images/' + key + '.xml');
	inline static public function modsTxt(key:String) return modFolders('images/' + key + '.txt');

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) return fileToCheck;
		}

		for(mod in getGlobalMods()) {
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck)) return fileToCheck;
		}
		return 'mods/' + key;
	}

	public static var globalMods:Array<String> = [];
	static public function getGlobalMods() return globalMods;

	static public function pushGlobalMods() {
		globalMods = [];
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path)) {
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list) {
				var dat = i.split("|");
				if (dat[1] == "1") {
					var folder = dat[0];
					var packPath = Paths.mods(folder + '/pack.json');
					if(FileSystem.exists(packPath)) {
						try {
							var rawJson:String = File.getContent(packPath);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								if(Reflect.getProperty(stuff, "runsGlobally")) globalMods.push(folder);
							}
						} catch(e:Dynamic) trace(e);
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if(FileSystem.exists(modsFolder)) {
			for (folder in FileSystem.readDirectory(modsFolder)) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end
}
