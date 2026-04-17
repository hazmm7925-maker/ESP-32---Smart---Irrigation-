# Smart Irrigation System (IoT-Based)

An automated irrigation solution designed to optimize water consumption and monitor plant health in real-time. This project leverages the **ESP32** microcontroller and IoT technology to bridge the gap between agriculture and smart monitoring.

## 🚀 Features
* **Real-time Monitoring:** Continuous tracking of soil moisture levels.
* **Cloud Integration:** Seamless data synchronization with **Firebase Realtime Database**.
* **Remote Control:** Manual control of the motor pump through a mobile application via WiFi.
* **Automation:** Intelligent watering logic based on soil moisture thresholds.

## 🛠️ Hardware Components
* **Microcontroller:** ESP32 (NodeMCU).
* **Sensor:** Soil Moisture Sensor.
* **Actuator:** DC Motor Pump.
* **Driver:** 2N2222 Transistor (used for motor switching).
* **Power Source:** External power supply for the pump.

## 💻 Tech Stack
* **Firmware:** C/C++ (Arduino framework/ESP-IDF).
* **Backend:** Firebase (Realtime Database).
* **Tools:** Visual Studio Code / Proteus for circuit simulation.

## 🔌 Circuit Diagram
*(You can upload your Proteus screenshot to the 'images' folder and link it here)*
![Circuit Diagram](images/circuit_design.png)

## 📖 How it Works
The ESP32 reads analog values from the soil moisture sensor. If the moisture level drops below a certain threshold, the system triggers the 2N2222 transistor to run the motor pump. All status updates are sent to the Firebase cloud, allowing the user to monitor and override the pump status from their smartphone.