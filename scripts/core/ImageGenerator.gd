extends Node
class_name ImageGenerator
## Ücretsiz AI görsel üretimi için Pollinations AI entegrasyonu
## Eski API endpoint'i kullanılıyor (API key gerektirmez)
## URL: https://image.pollinations.ai/prompt/

const POLLINATIONS_URL := "https://image.pollinations.ai/prompt/"
const DEFAULT_WIDTH := 256
const DEFAULT_HEIGHT := 256
const DEFAULT_MODEL := "flux"

signal generation_complete(image_path: String, success: bool, error_message: String)
signal generation_progress(status: String)

var _http_request: HTTPRequest
var _output_dir: String = "res://assets/generated/"

func _ready() -> void:
	_setup_output_directory()

func _setup_output_directory() -> void:
	# Çıktı klasörünü oluştur
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("assets/generated"):
		dir.make_dir("assets/generated")

## Skill ikonu üretir
## prompt: Görsel açıklaması
## output_name: Kaydedilecek dosya adı (örn: "lightning_chain.png")
## width/height: Görsel boyutu (varsayılan 256x256)
## model: flux, turbo, dev
func generate_skill_icon(prompt: String, output_name: String, width: int = DEFAULT_WIDTH, height: int = DEFAULT_HEIGHT, model: String = DEFAULT_MODEL) -> String:
	# Prompt'u URL-safe hale getir
	var encoded_prompt := _encode_prompt(prompt)
	var url := "%s%s?width=%d&height=%d&model=%s&nologo=true" % [POLLINATIONS_URL, encoded_prompt, width, height, model]

	generation_progress.emit("Görsel üretiliyor: %s" % output_name)

	# HTTP request oluştur
	if _http_request:
		_http_request.queue_free()

	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed.bind(output_name))

	var error := _http_request.request(url)
	if error != OK:
		generation_complete.emit("", false, "HTTP isteği başlatılamadı: %d" % error)
		return ""

	return ""  # Asenkron işlem, sinyal ile sonuç dönecek

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, output_name: String) -> void:
	if response_code != 200:
		var error_msg := "HTTP %d: Sunucu hatası" % response_code
		generation_complete.emit("", false, error_msg)
		return

	# Görseli kaydet (WebP veya PNG)
	var output_path := _output_dir.path_join(output_name)

	# İçerik tipini kontrol et
	var content_type := ""
	for header in headers:
		if header.to_lower().begins_with("content-type:"):
			content_type = header.split(":")[1].strip_edges().to_lower()

	# Uzantıyı belirle
	var ext := "png"
	if "webp" in content_type:
		ext = "webp"
	elif "jpeg" in content_type or "jpg" in content_type:
		ext = "jpg"

	# Dosya adını uzatıya göre güncelle
	if not output_name.ends_with("." + ext):
		output_path = _output_dir.path_join(output_name.get_basename() + "." + ext)

	# Dosyayı kaydet
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_buffer(body)
		file.close()
		generation_progress.emit("Kaydedildi: %s" % output_path)
		generation_complete.emit(output_path, true, "")
	else:
		generation_complete.emit("", false, "Dosya kaydedilemedi: %s" % output_path)

## Prompt'u URL-safe hale getir
func _encode_prompt(prompt: String) -> String:
	var encoded := prompt.uri_encode()
	# Boşlukları + ile değiştir (daha iyi sonuçlar için)
	encoded = encoded.replace("%20", "+")
	return encoded

## Toplu skill ikonu üretimi için hazır prompt şablonları
class SkillPrompts:
	static func lightning_chain() -> String:
		return "glowing electric lightning chain spell icon for game, transparent background, purple and blue lightning bolts, dark fantasy style, pixel art compatible, centered, 256x256"

	static func arcane_orb() -> String:
		return "arcane magic orb spell icon for game, transparent background, swirling purple energy sphere, mystical runes, dark fantasy style, pixel art compatible"

	static func dark_beam() -> String:
		return "dark energy beam spell icon for game, transparent background, purple-black laser beam, corrupted magic, dark fantasy style, pixel art compatible"

	static func thunder_strike() -> String:
		return "thunder strike spell icon for game, transparent background, lightning bolt striking from sky, storm clouds, dark fantasy style, pixel art compatible"

	static func fire_bolt() -> String:
		return "fire bolt projectile icon for game, transparent background, blazing fire arrow, orange and red flames, RPG style, pixel art compatible"

	static func toxic_circle() -> String:
		return "toxic poison area icon for game, transparent background, green poisonous cloud puddle, bubbling poison, dark fantasy style, pixel art compatible"

	static func ice_nova() -> String:
		return "ice nova frost spell icon for game, transparent background, freezing ice burst, blue crystalline patterns, dark fantasy style, pixel art compatible"

	static func holy_nova() -> String:
		return "holy light nova spell icon for game, transparent background, golden divine light burst, religious glow, fantasy style, pixel art compatible"

	static func infernal_circle() -> String:
		return "infernal fire circle icon for game, transparent background, hellfire ritual circle, burning flames, dark fantasy style, pixel art compatible"

	static func frost_explosion() -> String:
		return "frost explosion spell icon for game, transparent background, icy blast, shattered ice crystals, blue frost, dark fantasy style, pixel art compatible"

## Basit senkron görsel üretimi (küçük görseller için)
## Büyük görseller için generate_skill_icon kullan
func generate_simple(prompt: String, output_name: String) -> String:
	var thread := Thread.new()
	thread.start(_thread_generate.bind(prompt, output_name))
	# Not: Bu basit bir örnek, gerçek kullanımda sinyalleri bekle
	return ""

func _thread_generate(prompt: String, output_name: String) -> void:
	# Arka plan işlemi (gelecekte eklenebilir)
	pass
