# Nibras (HeartSafe)

A prototype safety-support system that combines a Flutter mobile
application with an ESP32 device over Bluetooth Low Energy (BLE). The
application includes heart-rate data display, emergency and rescuer
workflows, location-related functionality, and a CPR guidance screen.

> **Project status:** Prototype. The ESP32 firmware currently generates
> demonstration BPM values after an ADC threshold is crossed. It does
> not implement a validated heart-rate measurement algorithm. Nibras is
> not a certified medical device and must not be used as a substitute
> for professional medical care or emergency services.

## Table of contents

-   [Overview](#overview)
-   [Features](#features)
-   [System architecture](#system-architecture)
-   [Technology stack](#technology-stack)
-   [ESP32 hardware and firmware](#esp32-hardware-and-firmware)
-   [Repository structure](#repository-structure)
-   [Getting started](#getting-started)
-   [Permissions](#permissions)
-   [Limitations and safety](#limitations-and-safety)
-   [Contributing](#contributing)

## Overview

Nibras (identified as **HeartSafe** in the device firmware and
application BLE scan logic) is a mobile-and-hardware prototype intended
to support emergency-related workflows.

The Flutter application communicates with an ESP32 peripheral using BLE
to receive heart-rate measurement notifications. The application source
also includes emergency/rescuer workflows, location handling,
nearby-device communication, background service functionality, and a CPR
guidance interface.

## Features

The reviewed application source includes the following functionality:

-   **BLE heart-rate screen:** scans for a peripheral whose advertised
    name contains `HeartSafe`, connects to it, discovers the standard
    Heart Rate service, subscribes to measurement notifications, and
    displays the received BPM value.
-   **Emergency workflow:** provides an emergency interface and uses
    available heart-rate and location information in its SOS workflow.
-   **Rescuer workflow:** discovers nearby emergency broadcasts,
    receives emergency information, and calculates distance from
    location coordinates.
-   **Nearby-device communication:** uses Nearby Connections for
    exchanging SOS-related data between nearby devices.
-   **Fall-monitoring workflow:** uses the phone's user-accelerometer
    stream in the background safety workflow.
-   **Background service and notifications:** configures a background
    service and local notifications for ongoing safety-related
    functionality.
-   **CPR guidance:** presents four instructional steps using local
    images and Arabic text-to-speech narration.

Feature behavior can vary by Android version, device hardware,
permissions, Bluetooth/location settings, and operating-system
background-execution restrictions.

## System architecture

``` text
                    NIBRAS SYSTEM
┌─────────────────────────────────────────────┐
│              Flutter mobile app             │
│                                             │
│  Heart-rate screen     Emergency workflow   │
│  Rescuer workflow      CPR guidance         │
│  Location handling     Background service  │
└───────────────┬─────────────────┬───────────┘
                │                 │
             BLE             Nearby Connections
                │                 │
                ▼                 ▼
       ┌────────────────┐   ┌─────────────────┐
       │  ESP32 device  │   │ Nearby phones   │
       │  HeartSafe     │   │ SOS data exchange│
       └────────────────┘   └─────────────────┘
```

### Bluetooth Low Energy (BLE)

The ESP32 firmware advertises the device as `HeartSafe` and exposes the
Bluetooth SIG Heart Rate service.

  BLE item                                     Value
  -------------------------------------------- ---------------------
  Advertised device name                       `HeartSafe`
  Heart Rate service UUID                      `0x180D`
  Heart Rate Measurement characteristic UUID   `0x2A37`
  ESP32 BLE host stack                         NimBLE
  Flutter BLE package                          `flutter_blue_plus`

The Flutter application scans for the peripheral, connects, discovers
the service and characteristic, and enables notifications to receive
measurement data.

## Technology stack

### Mobile application

-   **Flutter / Dart** --- mobile application UI and logic.
-   `flutter_blue_plus` --- Bluetooth Low Energy scanning, connection,
    and notifications.
-   `nearby_connections` --- nearby-device discovery and data exchange.
-   `geolocator` --- location access and distance calculations.
-   `sensors_plus` --- phone sensor data, including user-accelerometer
    readings.
-   `flutter_background_service` --- background service functionality.
-   `flutter_local_notifications` --- local notifications.
-   `permission_handler` --- runtime permission handling.
-   `flutter_tts` --- text-to-speech narration.
-   `shared_preferences` --- local key-value persistence.
-   `audioplayers` and `maps_launcher` --- declared project
    dependencies.

The dependencies above are based on the project's `pubspec.yaml`. A
dependency being listed does not necessarily mean every package is used
in every application flow.

### ESP32 firmware

-   ESP-IDF
-   FreeRTOS
-   NimBLE Bluetooth LE
-   ADC driver
-   GPIO driver
-   ESP random-number generator

## ESP32 hardware and firmware

The reviewed firmware source (`main.c`) configures the following
interfaces:

  Interface                               Configuration
  --------------------------------------- --------------------------------------
  ADC input                               ADC1, channel 4
  Status LED                              GPIO 2
  Additional GPIO output                  GPIO 1, configured low in the source
  BLE stack                               NimBLE
  Heart Rate service                      `0x180D`
  Heart Rate Measurement characteristic   `0x2A37`

### Current BPM data behavior

The current firmware reads the ADC input periodically. When the raw ADC
reading is greater than `150`, it generates a demonstration BPM value
between **60 and 89** using the ESP32 random-number generator. If a BLE
client has enabled notifications, the generated value is sent to that
client.

The GATT characteristic read callback also returns a fixed value of
`75`. Therefore, the current firmware demonstrates BLE communication and
notification flow; it does **not** calculate a real heart rate from
detected pulse peaks.

## Repository structure

The repository is intended to be organized as follows:

``` text
Nibras/
├── README.md
├── .gitignore
│
├── mobile_app/
│   ├── android/
│   ├── assets/
│   ├── lib/
│   ├── test/
│   ├── pubspec.yaml
│   └── pubspec.lock
│
└── esp32_firmware/
    ├── main/
    │   ├── main.c
    │   └── CMakeLists.txt
    ├── CMakeLists.txt
    └── sdkconfig.defaults
```

This is the recommended repository layout. If the uploaded repository
uses different folder names or contains additional required ESP-IDF
files, update this section to match the actual committed files.

## Getting started

### Requirements

-   Flutter SDK compatible with the Dart SDK constraint in
    `mobile_app/pubspec.yaml`.
-   Android Studio or another supported Flutter development environment.
-   A physical Android phone is recommended for BLE, nearby-device,
    sensor, and location testing.
-   ESP-IDF configured for the target ESP32 board.
-   A compatible ESP32 board and the sensor/hardware wiring required by
    the firmware.

### Run the Flutter application

From the `mobile_app` directory:

``` bash
flutter pub get
flutter run
```

To build an Android APK:

``` bash
flutter build apk
```

### Build and flash the ESP32 firmware

From the ESP-IDF firmware project directory:

``` bash
idf.py build
idf.py -p PORT flash monitor
```

Replace `PORT` with the serial port connected to the ESP32.

The ESP-IDF project must include its required CMake files, component
dependencies, and configuration for the target board. The exact build
setup may need to be completed or adjusted to match the hardware and
ESP-IDF version being used.

### Connect the mobile application to the ESP32

1.  Build and flash the firmware to the ESP32.
2.  Power on the ESP32 and confirm that it advertises as `HeartSafe`.
3.  Enable Bluetooth on the Android phone.
4.  Grant the relevant Bluetooth permissions requested by the
    application.
5.  Open the heart-rate screen and start scanning.
6.  Connect to the discovered `HeartSafe` device and enable
    notifications if prompted.

## Permissions

Depending on the Android version and enabled features, the application
may request permissions related to:

-   Bluetooth scanning and connection.
-   Nearby devices.
-   Location access.
-   Notifications.
-   Sensor and background-service operation.
-   Other Android capabilities used by the emergency interface.

Grant permissions only when needed for the feature being tested. Some
functions also require Bluetooth, location services, and background
execution to be enabled in the phone's settings.

## Limitations and safety

-   The current ESP32 firmware generates demonstration BPM values after
    an ADC threshold is crossed; it does not implement a validated
    pulse-detection or heart-rate calculation algorithm.
-   The firmware's GATT read callback returns a fixed BPM value of `75`.
-   No clinical accuracy, medical certification, or emergency-response
    reliability is claimed.
-   Fall-monitoring behavior may be affected by phone sensor
    characteristics, device placement, permissions, and operating-system
    background restrictions.
-   Nearby SOS delivery depends on device compatibility, permissions,
    discovery, and connection availability.
-   This project is a prototype for development and evaluation. It is
    not a substitute for emergency services, professional medical
    assessment, or certified CPR training.

## Contributing

Contributions and improvements are welcome.

1.  Describe the proposed change or issue.
2.  Test changes on the target phone or ESP32 hardware where applicable.
3.  Update this README when setup instructions, dependencies, hardware
    configuration, or application behavior change.

------------------------------------------------------------------------

**Before publishing:** confirm that the repository folder names match
the structure above, include all required ESP-IDF project files, and
contain no credentials, private keys, personal data, or machine-specific
configuration files.
