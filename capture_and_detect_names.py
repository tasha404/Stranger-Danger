from picamera2 import Picamera2
import cv2
import pytesseract
import numpy as np
from datetime import datetime
import time
import os
import re

def setup_camera():
    """Initialize and configure the camera"""
    picam2 = Picamera2()
    
    # Configure for good text capture
    config = picam2.create_still_configuration(
        main={"size": (1920, 1080)},  # Good balance for OCR
        controls={
            "Brightness": 0.1,
            "Contrast": 1.5,
            "Sharpness": 2.0,
            "ExposureTime": 30000,
            "AnalogueGain": 2.0,
            "AwbEnable": True,
            "AeEnable": True,
        }
    )
    
    picam2.configure(config)
    return picam2

def preprocess_image_for_ocr(image):
    """Preprocess image to improve text detection"""
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Apply threshold to get binary image
    _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    # Noise removal
    kernel = np.ones((2, 2), np.uint8)
    processed = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
    
    return processed

def detect_names(image):
    """Extract names from image using OCR"""
    # Preprocess the image
    processed = preprocess_image_for_ocr(image)
    
    # Use pytesseract to extract text with custom configuration
    custom_config = r'--oem 3 --psm 6 -c tessedit_char_whitelist="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.- \'"'
    text = pytesseract.image_to_string(processed, config=custom_config)
    
    # Clean and extract potential names
    lines = text.split('\n')
    names = []
    
    # Patterns for name detection
    name_patterns = [
        r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b',  # First Last
        r'\b[A-Z][a-z]+\s+[A-Z]\.\s*[A-Z][a-z]+\b',  # First M. Last
        r'\b[A-Z][a-z]+,\s+[A-Z][a-z]+\b',  # Last, First
        r'\bMr\.\s+[A-Z][a-z]+\s+[A-Z][a-z]+\b',  # Mr. First Last
        r'\bMs\.\s+[A-Z][a-z]+\s+[A-Z][a-z]+\b',  # Ms. First Last
        r'\bMrs\.\s+[A-Z][a-z]+\s+[A-Z][a-z]+\b',  # Mrs. First Last
        r'\bDr\.\s+[A-Z][a-z]+\s+[A-Z][a-z]+\b',  # Dr. First Last
    ]
    
    for line in lines:
        line = line.strip()
        if line:
            # Check if line contains potential names
            for pattern in name_patterns:
                matches = re.findall(pattern, line)
                if matches:
                    names.extend(matches)
            # If no pattern matched, check if it looks like a name
            elif re.match(r'^[A-Z][a-z]+\s+[A-Z][a-z]+$', line):
                names.append(line)
    
    # Remove duplicates while preserving order
    unique_names = []
    for name in names:
        if name not in unique_names:
            unique_names.append(name)
    
    return unique_names, text

def draw_detections(image, names, original_text):
    """Draw bounding boxes around detected text and names"""
    # Get text bounding boxes
    data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
    
    # Create a copy to draw on
    output = image.copy()
    
    n_boxes = len(data['text'])
    for i in range(n_boxes):
        if int(data['conf'][i]) > 60:  # Confidence threshold
            (x, y, w, h) = (data['left'][i], data['top'][i], data['width'][i], data['height'][i])
            cv2.rectangle(output, (x, y), (x + w, y + h), (0, 255, 0), 2)
            
            # Put text number
            cv2.putText(output, str(i), (x, y-10), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)
    
    # Create information overlay
    overlay = output.copy()
    cv2.rectangle(overlay, (10, 10), (500, 100 + len(names)*30), (0, 0, 0), -1)
    output = cv2.addWeighted(overlay, 0.5, output, 0.5, 0)
    
    # Add text information
    cv2.putText(output, f"Detected Names: {len(names)}", (20, 40), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
    
    for idx, name in enumerate(names):
        cv2.putText(output, f"{idx+1}. {name}", (20, 80 + idx*30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
    
    return output

def capture_and_detect(picam2, save_annotated=True):
    """Capture image and detect names"""
    print("\n" + "="*50)
    print("CAPTURING AND DETECTING NAMES")
    print("="*50)
    
    # Start camera
    picam2.start()
    time.sleep(2)  # Let camera adjust
    
    # Create timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Capture image
    print("Capturing image...")
    image_array = picam2.capture_array()
    
    # Convert to OpenCV format (BGR)
    image_bgr = cv2.cvtColor(image_array, cv2.COLOR_RGB2BGR)
    
    # Save original image
    original_filename = f"original_{timestamp}.jpg"
    cv2.imwrite(original_filename, image_bgr)
    print(f"Original image saved: {original_filename}")
    
    # Detect names
    print("Processing image for text detection...")
    names, all_text = detect_names(image_bgr)
    
    # Display results
    print("\n" + "="*50)
    print("DETECTION RESULTS")
    print("="*50)
    print(f"\nAll detected text:\n{'-'*30}")
    print(all_text)
    print("-"*30)
    
    print(f"\nExtracted Names ({len(names)} found):")
    if names:
        for i, name in enumerate(names, 1):
            print(f"  {i}. {name}")
    else:
        print("  No names detected")
    
    # Create and save annotated image if requested
    if save_annotated and names:
        annotated = draw_detections(image_bgr, names, all_text)
        annotated_filename = f"annotated_{timestamp}.jpg"
        cv2.imwrite(annotated_filename, annotated)
        print(f"\nAnnotated image saved: {annotated_filename}")
    
    # Save results to text file
    results_filename = f"results_{timestamp}.txt"
    with open(results_filename, 'w') as f:
        f.write(f"Image Capture Results - {timestamp}\n")
        f.write("="*50 + "\n\n")
        f.write(f"Original Image: {original_filename}\n")
        if save_annotated and names:
            f.write(f"Annotated Image: {annotated_filename}\n")
        f.write("\nAll Detected Text:\n")
        f.write("-"*30 + "\n")
        f.write(all_text + "\n")
        f.write("-"*30 + "\n\n")
        f.write(f"Extracted Names ({len(names)}):\n")
        for i, name in enumerate(names, 1):
            f.write(f"{i}. {name}\n")
    
    print(f"\nResults saved to: {results_filename}")
    
    return names, original_filename

def continuous_monitoring(picam2, interval=10):
    """Continuously monitor and detect names"""
    print("\n" + "="*50)
    print("CONTINUOUS MONITORING MODE")
    print("="*50)
    print(f"Checking every {interval} seconds...")
    print("Press Ctrl+C to stop\n")
    
    picam2.start()
    time.sleep(2)
    
    try:
        capture_count = 0
        while True:
            capture_count += 1
            print(f"\nCapture #{capture_count} at {datetime.now().strftime('%H:%M:%S')}")
            
            # Capture
            image_array = picam2.capture_array()
            image_bgr = cv2.cvtColor(image_array, cv2.COLOR_RGB2BGR)
            
            # Detect names
            names, _ = detect_names(image_bgr)
            
            if names:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"monitor_{timestamp}.jpg"
                cv2.imwrite(filename, image_bgr)
                
                print(f"✓ Names detected! Saved as: {filename}")
                for name in names:
                    print(f"  - {name}")
            else:
                print("✗ No names detected")
            
            time.sleep(interval)
            
    except KeyboardInterrupt:
        print("\n\nMonitoring stopped")
    finally:
        picam2.stop()

def main():
    """Main menu"""
    print("="*60)
    print("RASPBERRY PI CAMERA - NAME DETECTION SYSTEM")
    print("="*60)
    
    # Check if Tesseract is available
    try:
        pytesseract.get_tesseract_version()
    except:
        print("ERROR: Tesseract OCR is not installed!")
        print("Install it with: sudo apt install tesseract-ocr")
        return
    
    # Setup camera
    picam2 = setup_camera()
    
    while True:
        print("\n" + "="*60)
        print("MAIN MENU")
        print("="*60)
        print("1. Single Capture & Name Detection")
        print("2. Continuous Monitoring")
        print("3. Test with Sample Image")
        print("4. View Recent Results")
        print("5. Exit")
        
        choice = input("\nSelect option (1-5): ").strip()
        
        if choice == '1':
            save_annotated = input("Save annotated image? (y/n): ").lower() == 'y'
            names, filename = capture_and_detect(picam2, save_annotated)
            
        elif choice == '2':
            try:
                interval = int(input("Monitoring interval (seconds): "))
                continuous_monitoring(picam2, interval)
            except ValueError:
                print("Please enter a valid number!")
            except KeyboardInterrupt:
                print("\nReturning to menu...")
                
        elif choice == '3':
            # Test with a prepared image
            test_image = input("Enter test image path (or press Enter for default): ")
            if not test_image:
                print("Create a test image first using option 1")
                continue
            
            if os.path.exists(test_image):
                image = cv2.imread(test_image)
                names, all_text = detect_names(image)
                print(f"\nDetected {len(names)} names:")
                for name in names:
                    print(f"  - {name}")
            else:
                print("File not found!")
                
        elif choice == '4':
            # List recent result files
            result_files = [f for f in os.listdir('.') if f.startswith('results_')]
            if result_files:
                print("\nRecent results:")
                for file in sorted(result_files)[-5:]:
                    print(f"  - {file}")
            else:
                print("No results found yet!")
                
        elif choice == '5':
            print("Exiting...")
            break
            
        else:
            print("Invalid option!")
    
    picam2.close()

if __name__ == "__main__":
    # Installation check and instructions
    print("Checking dependencies...")
    
    try:
        import cv2
        import pytesseract
        from picamera2 import Picamera2
    except ImportError as e:
        print(f"\nMissing dependency: {e}")
        print("\nInstall required packages with:")
        print("sudo apt update")
        print("sudo apt install python3-opencv tesseract-ocr")
        print("sudo apt install python3-picamera2")
        print("pip install pytesseract")
        exit(1)
    
    main()
