# Hardware Architecture

                   +-------------------+
                   |   Mobile Camera   |
                   | (Road Image Input)|
                   +---------+---------+
                             |
                             v
                   +-------------------+
                   |       ESP32       |
                   | Main Controller   |
                   +----+---------+----+
                        |         |
          +-------------+         +-------------+
          |                                   |
          v                                   v
+-------------------+            +-------------------+
| Ultrasonic Sensor |            |    GPS Module     |
| Measures Pothole  |            | Gets Location     |
| Depth             |            | (Latitude/Longitude)
+-------------------+            +-------------------+
          |                                   |
          +----------------+------------------+
                           |
                           v
                 +-------------------+
                 | AI Model (YOLO)   |
                 | Detects Potholes  |
                 | and Cracks        |
                 +---------+---------+
                           |
                           v
                 +-------------------+
                 | Severity Analysis |
                 | Low / Medium / High
                 +---------+---------+
                           |
                           v
                 +-------------------+
                 | Alert System      |
                 | User / Authority  |
                 +-------------------+
