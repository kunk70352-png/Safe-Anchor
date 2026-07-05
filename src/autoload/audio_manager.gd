## AudioManager — 全局音频管理单例。
## 统一控制 BGM 播放/切换，SFX 播放，音量调节。
extends Node

# ---- 常量 ----
const SFX_POOL_SIZE := 8

# ---- 内部状态 ----
var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _music_volume: float = 1.0
var _sfx_volume: float = 1.0
var _bgm_fade_tween: Tween

# ---- 生命周期 ----

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Music"
	add_child(_bgm_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_pool.append(p)


# ---- BGM ----

func play_bgm(stream: AudioStream, fade_in: float = 0.5) -> void:
	if not stream:
		return
	if _bgm_player.playing and _bgm_player.stream == stream:
		return
	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()
	_bgm_player.stream = stream
	_bgm_player.volume_db = -40
	_bgm_player.play()
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(_bgm_player, "volume_db", linear_to_db(_music_volume), fade_in)


func stop_bgm(fade_out: float = 0.5) -> void:
	if not _bgm_player.playing:
		return
	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(_bgm_player, "volume_db", -40, fade_out)
	_bgm_fade_tween.tween_callback(_bgm_player.stop)


# ---- SFX ----

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	var p := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db + linear_to_db(_sfx_volume)
	p.pitch_scale = pitch_scale
	p.play()


# ---- 音量 ----

func set_music_volume(linear: float) -> void:
	_music_volume = clampf(linear, 0.0, 1.0)
	_bgm_player.volume_db = linear_to_db(_music_volume)


func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clampf(linear, 0.0, 1.0)


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume