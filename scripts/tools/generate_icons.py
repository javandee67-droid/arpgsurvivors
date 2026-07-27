#!/usr/bin/env python3
"""
Ücretsiz AI Skill Sprite Frame Üretici - Pollinations AI
Her skill için animasyon frame'leri üretir (sprite sheet desteği)

Kullanım:
    python generate_sprites.py --skill lightning_chain --frames 8
    python generate_sprites.py --all --frames 6
    python generate_sprites.py --projectile fire_bolt --frames 8

Önemli: --frames ile her skill için kaç frame üretileceğini belirtin!
"""

import urllib.request
import urllib.parse
import os
import time
import argparse
from pathlib import Path

# Pollinations API (ücretsiz, API key gerektirmez)
POLLINATIONS_URL = "https://image.pollinations.ai/prompt/"

# Çıktı klasörü
OUTPUT_DIR = Path("res://assets/generated")

# Frame sayısı (animasyon için)
DEFAULT_FRAMES = 6  # 6 FPS * 6 frames = ~1 saniye animasyon

# Sprite frame boyutu (oyun için 128x128 idealdir)
DEFAULT_WIDTH = 128
DEFAULT_HEIGHT = 128


def create_output_dir():
    """Çıktı klasörünü oluştur"""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Çıktı klasörü: {OUTPUT_DIR}")


def generate_sprite_frame(prompt: str, filename: str, frame_num: int, 
                          total_frames: int, width: int, height: int, 
                          model: str = "flux") -> Path:
    """Tek bir sprite frame üret"""
    
    # Frame bilgisini prompt'a ekle (tutarlılık için)
    frame_prompt = f"{prompt}, sprite animation frame {frame_num + 1} of {total_frames}"
    
    # URL encode
    encoded_prompt = urllib.parse.quote(frame_prompt, safe='')
    encoded_prompt = encoded_prompt.replace('%20', '+')
    
    url = f"{POLLINATIONS_URL}{encoded_prompt}?width={width}&height={height}&model={model}&nologo=true"
    
    output_path = OUTPUT_DIR / filename
    
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=60) as response:
            data = response.read()
        
        with open(output_path, 'wb') as f:
            f.write(data)
        
        size = len(data) / 1024
        return output_path
        
    except Exception as e:
        print(f"    ✗ Frame {frame_num} hata: {e}")
        return None


def generate_skill_sprite(skill_name: str, prompt: str, num_frames: int = DEFAULT_FRAMES,
                          width: int = DEFAULT_WIDTH, height: int = DEFAULT_HEIGHT,
                          model: str = "flux") -> list:
    """Skill için sprite animasyon frame'leri üret"""
    
    print(f"\n  Skill: {skill_name}")
    print(f"  Frame sayısı: {num_frames}")
    print(f"  Boyut: {width}x{height}")
    
    results = []
    
    for i in range(num_frames):
        filename = f"{skill_name}_frame_{i}.png"
        print(f"  [{i+1}/{num_frames}] Üretiliyor: {filename}", end=" ... ")
        
        result = generate_sprite_frame(prompt, filename, i, num_frames, 
                                        width, height, model)
        results.append((filename, result))
        
        if result:
            size = os.path.getsize(result) / 1024
            print(f"✓ ({size:.1f} KB)")
        else:
            print("✗ HATA")
        
        # Rate limit'e takılmamak için bekleme
        time.sleep(0.5)
    
    success = sum(1 for _, r in results if r)
    print(f"  Sonuç: {success}/{num_frames} başarılı")
    
    return results


# ============================================================
# SPRITE PROMPT KÜTÜPHANESİ
# Her skill için 6-8 frame'lik animasyon promptları
# ============================================================

SPRITE_PROMPTS = {
    # === MELEE/SLASH SKILLS (6-8 frame) ===
    "slash": {
        "prompt": "melee sword slash attack sprite for game, transparent background, warrior sword swinging in arc motion, metallic blade with white trail effect, dark fantasy RPG style",
        "frames": 6,
        "desc": "Kılıç salvosı"
    },
    "slice_wave": {
        "prompt": "crescent sword wave projectile sprite for game, transparent background, steel sword slash creating crescent energy wave traveling forward, metallic silver and white, RPG action game style",
        "frames": 8,
        "desc": "Kılıç dalgası"
    },
    "whirlwind": {
        "prompt": "whirlwind spinning attack sprite for game, transparent background, tornado wind vortex spinning rapidly, dust and debris particles swirling, fantasy RPG action style",
        "frames": 8,
        "desc": "Kasırga"
    },
    
    # === PROJECTILE SKILLS (6-8 frame) ===
    "fire_bolt": {
        "prompt": "fire projectile sprite for game, transparent background, blazing fireball arrow flying forward with orange flames and smoke trail, hot embers, RPG action game style",
        "frames": 8,
        "desc": "Ateş oku"
    },
    "arcane_orb": {
        "prompt": "arcane magic orb projectile sprite for game, transparent background, swirling purple energy sphere with mystical runes orbiting, dark magic, fantasy RPG style",
        "frames": 8,
        "desc": "Gizem küresi"
    },
    "ice_shard": {
        "prompt": "ice shard projectile sprite for game, transparent background, sharp crystalline ice spike flying with frost trail, blue white colors, frozen magic, RPG style",
        "frames": 6,
        "desc": "Buz parçası"
    },
    "dark_beam": {
        "prompt": "dark energy beam projectile sprite for game, transparent background, purple-black corruption beam shooting forward with particle effects, dark magic fantasy RPG style",
        "frames": 8,
        "desc": "Karanlık ışın"
    },
    "lightning_chain": {
        "prompt": "lightning chain spell sprite for game, transparent background, electric purple-blue lightning bolt chaining between targets, branching electric arcs, fantasy RPG style",
        "frames": 6,
        "desc": "Yıldırım zinciri"
    },
    "holy_nova": {
        "prompt": "holy divine light projectile sprite for game, transparent background, golden holy light burst expanding outward, religious angelic glow, fantasy RPG style",
        "frames": 6,
        "desc": "Kutsal ışın"
    },
    
    # === AOE/EXPLOSION SKILLS (6-8 frame) ===
    "thunder_strike": {
        "prompt": "thunder lightning strike AOE sprite for game, transparent background, lightning bolt striking down from clouds with electric sparks explosion, dramatic impact, fantasy RPG style",
        "frames": 8,
        "desc": "Gök gürültüsü"
    },
    "ice_nova": {
        "prompt": "ice nova frost burst sprite for game, transparent background, freezing ice explosion expanding in circular pattern, crystalline frost shards radiating, blue white, fantasy RPG",
        "frames": 8,
        "desc": "Buz patlaması"
    },
    "frost_explosion": {
        "prompt": "frost explosion sprite for game, transparent background, icy blast with shattered ice crystals exploding outward, blue frost particles, fantasy RPG style",
        "frames": 6,
        "desc": "Buz patlaması"
    },
    "infernal_circle": {
        "prompt": "infernal hellfire ritual circle sprite for game, transparent background, hellfire flames rising from circular summoning rune, demonic fire, dark fantasy RPG",
        "frames": 8,
        "desc": "Cehennem ateşi"
    },
    "toxic_circle": {
        "prompt": "toxic poison puddle sprite for game, transparent background, green poisonous cloud bubbling on ground, corrosive acid bubbles popping, dark fantasy RPG style",
        "frames": 6,
        "desc": "Zehir havuzu"
    },
    "holy_nova_aoe": {
        "prompt": "holy divine nova AOE sprite for game, transparent background, golden sacred light exploding in all directions, radiant holy burst, angelic fantasy RPG style",
        "frames": 8,
        "desc": "Kutsal nova"
    },
    "fireball_impact": {
        "prompt": "fireball explosion impact sprite for game, transparent background, blazing fire explosion with orange flames expanding, smoke and embers flying, RPG action style",
        "frames": 8,
        "desc": "Ateş topu çarpması"
    },
    
    # === BUFF/AURA SPRITES (4-6 frame) ===
    "haste_aura": {
        "prompt": "haste speed buff aura sprite for game, transparent background, orange wind speed lines swirling around character, motion blur effect, fantasy RPG style",
        "frames": 6,
        "desc": "Hız artışı"
    },
    "determination_shield": {
        "prompt": "determination armor buff aura sprite for game, transparent background, golden warrior shield barrier glowing, protective steel aura, fantasy RPG style",
        "frames": 4,
        "desc": "Zırh buff"
    },
    "discipline_barrier": {
        "prompt": "discipline energy shield aura sprite for game, transparent background, blue magical barrier with glowing runes, mana shield effect, fantasy RPG style",
        "frames": 4,
        "desc": "Mana kalkanı"
    },
    
    # === MOVEMENT SPRITES (6 frame) ===
    "dash_trail": {
        "prompt": "dash movement speed trail sprite for game, transparent background, blue afterimage streak showing rapid forward dash motion, speed lines, fantasy RPG style",
        "frames": 6,
        "desc": "Fırlama"
    },
    
    # === HIT IMPACT SPRITES (4-6 frame) ===
    "hit_impact": {
        "prompt": "hit impact effect sprite for game, transparent background, damage number burst with red impact stars, enemy hit reaction, RPG style",
        "frames": 4,
        "desc": "Hasar etkisi"
    },
    "crit_impact": {
        "prompt": "critical hit impact effect sprite for game, transparent background, massive red critical damage burst with gold sparkles, devastating hit, RPG style",
        "frames": 6,
        "desc": "Kritik vuruş"
    },
    "lightning_impact": {
        "prompt": "lightning strike hit impact sprite for game, transparent background, electric bolt hitting enemy with sparks and flash, blue white discharge, fantasy RPG",
        "frames": 6,
        "desc": "Yıldırım çarpması"
    },
    "fire_impact": {
        "prompt": "fire hit impact sprite for game, transparent background, burning fire burst on enemy hit, orange flames and smoke, RPG action style",
        "frames": 4,
        "desc": "Ateş çarpması"
    },
    "ice_impact": {
        "prompt": "ice freeze impact sprite for game, transparent background, frost freeze burst on enemy, ice crystals forming, blue frost effect, fantasy RPG",
        "frames": 6,
        "desc": "Buz çarpması"
    },
    
    # === STATUS EFFECTS (4-6 frame) ===
    "burn_effect": {
        "prompt": "burning fire status effect sprite for game, transparent background, character or enemy on fire with flames rising, orange red flames, RPG status effect",
        "frames": 4,
        "desc": "Yanma efekti"
    },
    "freeze_effect": {
        "prompt": "frozen status effect sprite for game, transparent background, character encased in ice with frost crystals, blue white ice prison, RPG status effect",
        "frames": 4,
        "desc": "Dondurma efekti"
    },
    "poison_effect": {
        "prompt": "poisoned status effect sprite for game, transparent background, green toxic bubbles and fumes rising, corruption effect, dark fantasy RPG style",
        "frames": 4,
        "desc": "Zehir efekti"
    },
    "shock_effect": {
        "prompt": "shocked electrocuted status sprite for game, transparent background, electricity arcing around character with sparks, blue purple lightning, RPG status effect",
        "frames": 4,
        "desc": "Şok efekti"
    },
    
    # === ESSENCE GEMS (statik, tek frame) ===
    "essence_anger": {
        "prompt": "anger red ruby essence gem for game, transparent background, burning red gem with fire particles swirling inside, RPG item style",
        "frames": 1,
        "desc": "Öfke özü"
    },
    "essence_crit": {
        "prompt": "critical diamond essence gem for game, transparent background, sharp brilliant diamond with crackling energy, RPG item style",
        "frames": 1,
        "desc": "Kritik özü"
    },
    "essence_defense": {
        "prompt": "defense blue sapphire essence gem for game, transparent background, sturdy blue gem with shield shape, protective aura, RPG item style",
        "frames": 1,
        "desc": "Savunma özü"
    },
    "essence_speed": {
        "prompt": "speed green emerald essence gem for game, transparent background, swift green gem with wind trails, motion blur, RPG item style",
        "frames": 1,
        "desc": "Hız özü"
    },
    "essence_mana": {
        "prompt": "mana blue crystal essence gem for game, transparent background, deep blue magical crystal glowing with arcane energy, RPG item style",
        "frames": 1,
        "desc": "Mana özü"
    },
}


def generate_all_sprites(num_frames: int = DEFAULT_FRAMES, width: int = DEFAULT_WIDTH, 
                         height: int = DEFAULT_HEIGHT, model: str = "flux") -> list:
    """Tüm sprite'ları üret"""
    results = []
    
    print(f"\n{'='*60}")
    print(f"TOPLU SPRITE ÜRETİMİ")
    print(f"{'='*60}")
    print(f"Frame başına boyut: {width}x{height}")
    print(f"Her skill için frame sayısı: {num_frames}")
    print(f"Toplam skill: {len(SPRITE_PROMPTS)}")
    print(f"{'='*60}")
    
    skill_names = sorted(SPRITE_PROMPTS.keys())
    
    for i, skill_name in enumerate(skill_names):
        info = SPRITE_PROMPTS[skill_name]
        frames = info["frames"] if num_frames == 0 else num_frames
        
        print(f"\n[{i+1}/{len(skill_names)}] {skill_name.upper()}")
        print(f"    Açıklama: {info['desc']}")
        
        result = generate_skill_sprite(
            skill_name, 
            info["prompt"], 
            frames, 
            width, height, model
        )
        results.append((skill_name, result))
    
    # Özet
    print(f"\n{'='*60}")
    print("ÜRETİM ÖZETİ")
    print(f"{'='*60}")
    
    total_frames = 0
    success_frames = 0
    
    for skill_name, frames in results:
        for filename, result in frames:
            total_frames += 1
            if result:
                success_frames += 1
    
    print(f"Toplam frame: {total_frames}")
    print(f"Başarılı: {success_frames}")
    print(f"Başarısız: {total_frames - success_frames}")
    
    return results


def main():
    parser = argparse.ArgumentParser(
        description="Ücretsiz AI Sprite Frame Üretici - Pollinations AI\n" +
                   "Her skill için animasyon frame'leri üretir (sprite sheet desteği)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Örnekler:
    # Tek skill sprite (8 frame)
    python generate_sprites.py --skill fire_bolt --frames 8

    # Tüm sprite'ları üret (varsayılan 6 frame)
    python generate_sprites.py --all

    # Büyük boyut sprite (256x256)
    python generate_sprites.py --skill lightning_chain --frames 8 --size 256

    # Sadece skill listesini göster
    python generate_sprites.py --list

SPRITE TÜRLERİ:
    • Melee: slash, slice_wave, whirlwind
    • Projectile: fire_bolt, arcane_orb, ice_shard, dark_beam, lightning_chain, holy_nova
    • AOE: thunder_strike, ice_nova, frost_explosion, infernal_circle, toxic_circle, holy_nova_aoe, fireball_impact
    • Buff: haste_aura, determination_shield, discipline_barrier
    • Movement: dash_trail
    • Impact: hit_impact, crit_impact, lightning_impact, fire_impact, ice_impact
    • Effects: burn_effect, freeze_effect, poison_effect, shock_effect
    • Gems: essence_* (tek frame)
        """
    )
    
    parser.add_argument('--skill', '-s', type=str,
                        help='Tek bir skill sprite üret (örn: fire_bolt)')
    parser.add_argument('--all', '-a', action='store_true',
                        help='Tüm sprite\'ları üret')
    parser.add_argument('--list', '-l', action='store_true',
                        help='Mevcut sprite listesini göster')
    parser.add_argument('--frames', '-f', type=int, default=0,
                        help=f'Frame sayısı (varsayılan: skill başına özel değer, genellikle 6-8)')
    parser.add_argument('--size', type=int, default=DEFAULT_WIDTH,
                        help=f'Sprite boyutu (varsayılan: {DEFAULT_WIDTH})')
    parser.add_argument('--model', '-m', type=str, default='flux',
                        choices=['flux', 'turbo', 'dev'],
                        help='AI modeli (varsayılan: flux)')
    parser.add_argument('--fps', type=int, default=10,
                        help='Animasyon FPS değeri (varsayılan: 10)')
    
    args = parser.parse_args()
    
    create_output_dir()
    
    if args.list:
        print("\nMEVCUT SPRITE TÜRLERİ:")
        print("=" * 60)
        for name in sorted(SPRITE_PROMPTS.keys()):
            info = SPRITE_PROMPTS[name]
            print(f"  • {name:20s} - {info['desc']} (varsayılan: {info['frames']} frame)")
        return
    
    if args.all:
        generate_all_sprites(args.frames, args.size, args.size, args.model)
    elif args.skill:
        if args.skill not in SPRITE_PROMPTS:
            print(f"\nHata: '{args.skill}' sprite'ı bulunamadı!")
            print("\nKullanılabilir sprite'lar:")
            for name in sorted(SPRITE_PROMPTS.keys()):
                print(f"  - {name}")
            return
        
        info = SPRITE_PROMPTS[args.skill]
        frames = args.frames if args.frames > 0 else info["frames"]
        
        print(f"\n{'='*60}")
        print(f"SPRITE ÜRETİMİ: {args.skill}")
        print(f"{'='*60}")
        print(f"Açıklama: {info['desc']}")
        print(f"Frame sayısı: {frames}")
        print(f"Önerilen: {info['frames']}")
        
        results = generate_skill_sprite(
            args.skill,
            info["prompt"],
            frames,
            args.size,
            args.size,
            args.model
        )
        
        # Özet
        print(f"\n{'='*60}")
        print("SONUÇ:")
        success = sum(1 for _, r in results if r)
        print(f"  Başarılı: {success}/{frames} frame")
        print(f"  Çıktı: {OUTPUT_DIR}/{args.skill}_frame_*.png")
        
        if args.fps > 0 and success > 0:
            duration = frames / args.fps
            print(f"  Animasyon süresi: {duration:.1f} saniye (@ {args.fps} FPS)")
    else:
        parser.print_help()
        print("\n\nÖrnek kullanım:")
        print("  python generate_sprites.py --skill fire_bolt --frames 8")
        print("  python generate_sprites.py --all")
        print("  python generate_sprites.py --list")


if __name__ == "__main__":
    main()
