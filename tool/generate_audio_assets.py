import math
import os
import random
import struct
import wave

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
RATE = 22050


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b''.join(struct.pack('<h', max(-32768, min(32767, int(v * 32767)))) for v in samples))


def tone(seconds, frequency, decay=4.0, noise=0.0):
    count = int(RATE * seconds)
    rng = random.Random(42)
    return [
        (math.sin(2 * math.pi * frequency * i / RATE) + noise * (rng.random() * 2 - 1))
        * math.exp(-decay * i / count) * .55
        for i in range(count)
    ]


def main():
    write_wav('battle_attack.wav', tone(.22, 150, 8, .18))
    write_wav('battle_fire.wav', tone(.55, 72, 3, .45))
    write_wav('battle_charge.wav', tone(.32, 240, 5, .2))
    write_wav('battle_retreat.wav', tone(.3, 110, 5, .05))
    music = []
    notes = [110, 130.81, 146.83, 164.81, 146.83, 130.81]
    for note in notes * 4:
        music.extend(tone(.65, note, 1.4, .03))
    write_wav('battle_bgm.wav', [sample * .22 for sample in music])


if __name__ == '__main__':
    main()
