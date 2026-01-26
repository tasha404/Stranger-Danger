from picamera2 import Picamera2
import cv2
import pytesseract
import time
from datetime import datetime

# Quick capture and detect
picam2 = Picamera2()
config = picam2.create_still_configuration(main={"size": (1920, 1080)})
picam2.configure(config)

print("Starting camera...")
picam2.start()
time.sleep(2)

print("Capturing image...")
image_array = picam2.capture_array()
image_bgr = cv2.cvtColor(image_array, cv2.COLOR_RGB2BGR)

# Save image
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
filename = f"detect_{timestamp}.jpg"
cv2.imwrite(filename, image_bgr)

# Simple text detection
text = pytesseract.image_to_string(image_bgr)
print("\nDetected text:")
print("-" * 40)
print(text)
print("-" * 40)

# Look for names (simple pattern)
import re
lines = text.split('\n')
names = []

for line in lines:
    line = line.strip()
    if line:
        # Simple name pattern: Two capitalized words
        if re.match(r'^[A-Z][a-z]+\s+[A-Z][a-z]+$', line):
            names.append(line)
        # Pattern with title
        elif re.match(r'^(Mr|Ms|Mrs|Dr)\.\s+[A-Z][a-z]+\s+[A-Z][a-z]+$', line):
            names.append(line)

print(f"\nPossible names found: {len(names)}")
for name in names:
    print(f"  - {name}")

# Save results
with open(f"results_{timestamp}.txt", 'w') as f:
    f.write(f"Image: {filename}\n")
    f.write(f"Names found: {len(names)}\n")
    for name in names:
        f.write(f"{name}\n")

print(f"\nImage saved: {filename}")
print(f"Results saved: results_{timestamp}.txt")

picam2.stop()
picam2.close()
