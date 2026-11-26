/*
 * Suvarna controller firmware. Reference pin map for classic ESP32 DevKit.
 * GPIO34, GPIO35: joystick VRx and VRy. Use 3.3 V and common ground.
 * GPIO25, GPIO26, GPIO27, GPIO14: interact, slash, start, reset.
 * Each switch closes to ground. The firmware enables internal pull-ups.
 * GPIO2: active-high status LED. Check the LED circuit on the actual board.
 * USB serial: 115200 baud, 25 ms frames: SV1,x,y,interact,slash,start,reset.
 */
#include <Arduino.h>

constexpr int JOYSTICK_X = 34;
constexpr int JOYSTICK_Y = 35;
constexpr int INTERACT = 25;
constexpr int SLASH = 26;
constexpr int START = 27;
constexpr int RESET = 14;
constexpr int STATUS_LED = 2;
constexpr unsigned long FRAME_INTERVAL = 25;
constexpr unsigned long CONNECTION_TIMEOUT = 1400;

unsigned long nextFrame = 0;
unsigned long lastAcknowledged = 0;
bool acknowledged = false;
int x = 2048;
int y = 2048;

int activeLow(int pin) {
  return digitalRead(pin) == LOW ? 1 : 0;
}

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  pinMode(INTERACT, INPUT_PULLUP);
  pinMode(SLASH, INPUT_PULLUP);
  pinMode(START, INPUT_PULLUP);
  pinMode(RESET, INPUT_PULLUP);
  pinMode(STATUS_LED, OUTPUT);
  x = analogRead(JOYSTICK_X);
  y = analogRead(JOYSTICK_Y);
}

void loop() {
  const unsigned long now = millis();
  while (Serial.available() > 0) {
    if (Serial.read() == '1') {
      acknowledged = true;
      lastAcknowledged = now;
    }
  }
  // The bridge sends '1' after Godot acknowledges a valid packet.
  const bool linked = acknowledged && now - lastAcknowledged < CONNECTION_TIMEOUT;
  digitalWrite(STATUS_LED, linked || (now / 290) % 2 == 0 ? HIGH : LOW);
  if (now - nextFrame < FRAME_INTERVAL) {
    return;
  }
  nextFrame = now;
  // A short integer smoother reduces joystick jitter between samples.
  x = (x * 3 + analogRead(JOYSTICK_X)) / 4;
  y = (y * 3 + analogRead(JOYSTICK_Y)) / 4;
  Serial.printf("SV1,%d,%d,%d,%d,%d,%d\n", x, y, activeLow(INTERACT), activeLow(SLASH),
                activeLow(START), activeLow(RESET));
}
