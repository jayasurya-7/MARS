"""Build-time only. Generate generic guidance clips; no patient data is sent.
Runtime uses bundled MP3 files and needs neither Python nor internet.
Requires gTTS. Review phrases.json before regenerating.
"""
import json
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from gtts import gTTS

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'voice'
phrases = json.loads((ROOT / 'phrases.json').read_text(encoding='utf-8'))

def generate(item):
    language, key, text = item
    output = ROOT / language / (key + '.mp3')
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists() and output.stat().st_size > 1000:
        return str(output.name) + ' cached'
    gTTS(text=text, lang=language, timeout=30).save(str(output))
    return language + '/' + key

if __name__ == '__main__':
    jobs = [(lang, key, text) for lang, entries in phrases.items() for key, text in entries.items()]
    with ThreadPoolExecutor(max_workers=3) as pool:
        for result in pool.map(generate, jobs):
            print(result, flush=True)
