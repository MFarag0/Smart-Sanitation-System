# Lifelines_Hackathon_CMUQ
Team MindForge - Hackathon '26

Problem Statement: HPS#1 - Mapping Sanitation and Hygiene Services in Displaced Communities

Solution: WASH-Command Snap-Kit

WASH-Command Snap-Kit is an offline-first system that turns sanitation signals into a prioritized workflow. Instead of only displaying readings, it ranks urgency and supports task assignment across facilities.
In many displaced communities, shared toilets and handwashing points fail without warning: water runs low, soap runs out, and latrine pits approach overflow. Families lose basic hygiene access, and staff often discover issues late through complaints or manual rounds. This is a public health risk. WHO links cholera transmission to unsafe water, inadequate sanitation, and insufficient hygiene, and notes that contaminated water and poor sanitation are linked to diseases such as cholera and diarrhoea.
Hence, our solution creates a proactive service loop that prevents breakdowns. Restock soap and refill water before facilities become unusable and prioritize cleaning using measured usage so the busiest blocks are serviced first. Evidence from systematic reviews links handwashing with soap to lower diarrhoeal disease risk, making reliable soap availability an important operational target.

To setup this project, two main systems are required to be initialized:

1- Flutter-based Cross-platform Application: This serves as the main interface of the project. Your device needs to have flutter SDK installed in order to run the app, which can then be ran using VS Code. For the best experience, this application works best on desktop. Therefore, it is better to run the app on web browsers like Google Chrome or Microsoft Edge.

2- ESP32 Microcontroller Program: The microcontroller needs to have a program loaded on it using Arduino IDE, where the board's type is "TTGO LoRa32-OLED" when choosing the board on Arduino. As this program is specific to each microcontroller used, the port numbers mentioned at the beginning of the code will need to align with the microcontroller connected. To setup, begin by installing Arduino IDE, then install the ESP32 Library from the library section.

For running the Flutter application, begin by opening a new terminal referencing the project's file, then type "flutter pub get" to automatically install all the dependencies needed on your device. Then, type "flutter run" to run the application, and you can choose to run it on any available platform listed on your terminal.

For running the microcontroller program, after doing the correct setup, connect an ESP32 with the required sensors that is mentioned in the project's proposal, then simply upload the code to the microcontroller. Please note that this code is hardware-specific, meaning it may not work on your end provided that you did not do the necessary changes (e.g. changing the pin numbers, connecting the correct type of sensors).
