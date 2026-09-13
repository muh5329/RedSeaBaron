"""Original seamless filtered-noise breeze. Writes only wind.wav."""
import math, pathlib, random, struct, wave, json
rate, seconds = 22050, 12
count = rate * seconds
rng = random.Random(87012)
noise = [rng.uniform(-1, 1) for _ in range(count)]
# Run the same circular noise twice to settle the filter at the loop seam.
slow = fast = 0.0
samples = []
for lap in range(2):
    for i, value in enumerate(noise):
        fast += .11 * (value-fast)
        slow += .008 * (value-slow)
        if lap:
            phase = 2 * math.pi * i/count
            gust = .70 + .18*math.sin(phase+.7) + .10*math.sin(phase*3+1.2)
            samples.append((fast-slow)*gust)
rms = math.sqrt(sum(v*v for v in samples)/count)
samples = [v*.12/rms for v in samples]
assert max(abs(v) for v in samples) < .8
out = pathlib.Path(__file__).resolve().parents[1]/'assets/sfx/wind.wav'
with wave.open(str(out), 'wb') as stream:
    stream.setnchannels(1); stream.setsampwidth(2); stream.setframerate(rate)
    stream.writeframes(b''.join(struct.pack('<h', round(v*32767)) for v in samples))
print(json.dumps({'seconds':seconds,'samples':count,'rms':.12,'peak':max(abs(v) for v in samples),'seam_step':abs(samples[-1]-samples[0]),'bytes':out.stat().st_size}))
