extends Node

class BGM:
	static var rand = RandomNumberGenerator.new()
	static var last_track := -1
	static var tracks:Array[AudioStream] = [
		preload("res://game/resources/audio/bgm/succubus.ogg"),
		preload("res://game/resources/audio/bgm/space ambience.ogg"),
		preload("res://game/resources/audio/bgm/chronos.ogg"),
		preload("res://game/resources/audio/bgm/this is electro.ogg")
	]
	
	static func get_random() -> AudioStream:
		var num := rand.randi_range(0, tracks.size() - 1)
		while num == last_track:
			num = rand.randi_range(0, tracks.size() - 1)
		
		return tracks[num]

class SFX:
	static var gunshot := preload("res://game/resources/audio/effects/gunshot.wav")
	static var explosion := preload("res://game/resources/audio/effects/explosion.wav")
	
	class Menu:
		pass

"""
Music attribution
Succubus - Alexander Nakarada
Chronos - Alexander Nakarada
Space Ambience - Alexander Nakarada
This Is Electro - Claus Appel
"""
