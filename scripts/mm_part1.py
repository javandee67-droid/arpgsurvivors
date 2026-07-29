extends CanvasLayer
class_name MainMenu
## DuskForged Main Menu
signal start_new_game()
signal continue_game()
signal open_upgrades()
signal open_settings()
signal quit_game()
enum State { MAIN, UPGRADES, SETTINGS, CONFIRM_NEW_GAME }
var current_state: State = State.MAIN
var persistent_upgrades: PersistentUpgrades
const BG_COLOR := Color(0.02, 0.02, 0.04, 1.0)
const ACCENT_GOLD := Color(1.0, 0.78, 0.2, 1.0)
const ACCENT_SUBTLE := Color(0.85, 0.65, 0.25, 1.0)
const TEXT_MAIN := Color(0.92, 0.9, 0.85, 1.0)
const TEXT_MUTED := Color(0.5, 0.5, 0.55, 1.0)
const TEXT_DIM := Color(0.35, 0.35, 0.4, 1.0)
const HIGHLIGHT := Color(1.0, 0.92, 0.6, 1.0)
const DANGER := Color(0.9, 0.3, 0.2, 1.0)
const SUCCESS := Color(0.3, 0.85, 0.5, 1.0)
const BLUE_ACCENT := Color(0.4, 0.7, 1.0, 1.0)
const PANEL_BG := Color(0.04, 0.04, 0.08, 0.97)
const PANEL_BORDER := Color(0.35, 0.35, 0.4, 0.6)
const CARD_BG := Color(0.07, 0.07, 0.12, 0.85)
const CARD_BORDER := Color(0.15, 0.15, 0.2, 0.5)
const FONT_TITLE := 56
const FONT_SUBTITLE := 16
const FONT_BUTTON := 16
const FONT_SMALL := 12
const FONT_TINY := 10
const FONT_SECTION := 14
const FONT_PANEL_TITLE := 22
var _buttons: Array[Button] = []
var _gold_label: Label = null
var _title_label: Label = null
var _particles_node: Node2D = null
var _anim_time: float = 0.0
var _current_panel: Control = null
