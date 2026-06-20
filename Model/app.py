import cv2
import serial
import requests
from ultralytics import YOLO

# 1️⃣ Connect to ESP32 Bluetooth / Serial
ser = serial.Serial('COM5', 115200)  # Change COM port

# 2️⃣ Load YOLO26 Model
model = YOLO("yolo26n.pt")  # or your trained model: best.pt

# 3️⃣ Server URL
SERVER_URL = "http://127.0.0.1:5000/data"

# 4️⃣ Start webcam / mobile camera
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    # 🔹 YOLO26 Detection
    results = model(frame)[0]
    yolo_detected = len(results.boxes) > 0
    severity = "Low"

    # 🔹 Read ESP32 Data
    depth = 0
    lat, lon = None, None

    if ser.in_waiting:
        data = ser.readline().decode().strip()
        try:
            lat, lon, depth = map(float, data.split(","))
        except:
            pass

    # 🔹 SENSOR FUSION LOGIC
    final_status = "Normal"
    if yolo_detected and depth > 30:
        final_status = "High Pothole"
        severity = "High"
    elif yolo_detected:
        final_status = "Medium Pothole"
        severity = "Medium"
    elif depth > 30:
        final_status = "Possible Pothole"
        severity = "Medium"

    print(f"Status: {final_status}, Depth: {depth}, Lat:{lat}, Lon:{lon}")

    # 🔹 Send to server
    if lat and lon:
        payload = {
            "lat": lat,
            "lon": lon,
            "depth": depth,
            "detected": yolo_detected,
            "severity": severity
        }
        try:
            requests.post(SERVER_URL, json=payload)
        except:
            pass

    # 🔹 Display annotated frame
    annotated = results.plot()
    cv2.putText(annotated, final_status, (20, 40),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0,0,255), 2)
    cv2.imshow("Pothole & Crack Fusion", annotated)

    if cv2.waitKey(1) == 27:  # ESC to exit
        break

cap.release()
cv2.destroyAllWindows()