# simple_capture_names.py
from picamera2 import Picamera2
import time
from datetime import datetime
import cv2
import os

def setup_camera():
    """Initialize the camera"""
    camera = Picamera2()
    
    # Simple configuration
    config = camera.create_still_configuration(
        main={"size": (1920, 1080)},
        controls={
            "Brightness": 0.1,
            "Contrast": 1.2,
            "Sharpness": 1.0,
        }
    )
    
    camera.configure(config)
    return camera

def capture_image(camera, filename=None):
    """Capture a single image"""
    if filename is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"capture_{timestamp}.jpg"
    
    print(f"Taking picture: {filename}")
    
    camera.start()
    time.sleep(2)  # Let camera adjust
    
    camera.capture_file(filename)
    camera.stop()
    
    print(f"Saved: {filename}")
    return filename

def check_for_text(image_path):
    """Simple text check - you can expand this later"""
    try:
        # Read the image
        image = cv2.imread(image_path)
        if image is None:
            return "Could not read image"
        
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Simple text detection using OpenCV contours
        # This is a basic method - for real OCR, install pytesseract later
        _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY_INV)
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Filter contours that might be text
        text_contours = []
        for contour in contours:
            x, y, w, h = cv2.boundingRect(contour)
            area = cv2.contourArea(contour)
            
            # Simple heuristics for text-like shapes
            if area > 100 and w > 10 and h > 10 and w < 500 and h < 100:
                text_contours.append((x, y, w, h))
        
        return f"Found {len(text_contours)} potential text areas"
        
    except Exception as e:
        return f"Error: {str(e)}"

def main():
    """Main function"""
    print("=" * 50)
    print("SIMPLE RASPBERRY PI CAMERA CAPTURE")
    print("=" * 50)
    
    # Setup camera
    camera = setup_camera()
    
    try:
        while True:
            print("\nOptions:")
            print("1. Take a picture")
            print("2. Take multiple pictures")
            print("3. Check last picture for text")
            print("4. Exit")
            
            choice = input("\nSelect option (1-4): ").strip()
            
            if choice == '1':
                # Take single picture
                filename = capture_image(camera)
                
                # Ask if user wants to check for text
                check = input("Check this image for text? (y/n): ").strip().lower()
                if check == 'y':
                    result = check_for_text(filename)
                    print(f"Text detection: {result}")
            
            elif choice == '2':
                # Take multiple pictures
                try:
                    count = int(input("How many pictures? "))
                    delay = float(input("Delay between pictures (seconds)? "))
                    
                    for i in range(count):
                        filename = f"multi_{i+1}_{datetime.now().strftime('%H%M%S')}.jpg"
                        capture_image(camera, filename)
                        
                        if i < count - 1:
                            print(f"Waiting {delay} seconds...")
                            time.sleep(delay)
                    
                    print(f"\nCompleted: {count} pictures taken")
                    
                except ValueError:
                    print("Please enter valid numbers!")
            
            elif choice == '3':
                # Check last picture
                jpg_files = [f for f in os.listdir('.') if f.endswith('.jpg')]
                if jpg_files:
                    latest = max(jpg_files, key=os.path.getctime)
                    print(f"Checking latest image: {latest}")
                    result = check_for_text(latest)
                    print(f"Result: {result}")
                else:
                    print("No pictures found!")
            
            elif choice == '4':
                print("Goodbye!")
                break
            
            else:
                print("Invalid option. Please choose 1-4.")
    
    except KeyboardInterrupt:
        print("\n\nProgram stopped by user")
    
    finally:
        camera.close()
        print("Camera closed.")

if __name__ == "__main__":
    main()
