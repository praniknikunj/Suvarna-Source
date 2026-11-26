#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

// Joystick pins
const int JOY_X  = 34;
const int JOY_Y  = 35;
const int JOY_SW = 32;

// Four physical buttons
const int MENU_BTN   = 25;
const int RED_BTN    = 26;
const int MAP_BTN    = 27;
const int ACTION_BTN = 14;

// Joystick activation thresholds
const int LOW_THRESHOLD  = 1200;
const int HIGH_THRESHOLD = 2800;

// Hysteresis release thresholds
const int LOW_RELEASE  = 1450;
const int HIGH_RELEASE = 2650;

const unsigned long DEBOUNCE_MS = 35;

// Button structure
struct Button {
  int pin;
  const char* command;
  bool lastReading;
  bool stableState;
  unsigned long lastChange;
};

// Button mappings
Button buttons[] = {
  {MENU_BTN,   "SLASH",    HIGH, HIGH, 0},
  {RED_BTN,    "THRUST",   HIGH, HIGH, 0},
  {MAP_BTN,    "INTERACT", HIGH, HIGH, 0},
  {ACTION_BTN, "PAUSE",    HIGH, HIGH, 0}
};

const int BUTTON_COUNT =
  sizeof(buttons) / sizeof(buttons[0]);

// Joystick switch
bool lastSWReading = HIGH;
bool stableSWState = HIGH;
unsigned long lastSWChange = 0;

// Joystick axis states:
// -1 = negative direction
//  0 = neutral
//  1 = positive direction
int xDirection = 0;
int yDirection = 0;

String lastMovement = "";

// Send Bluetooth command
void sendCommand(const String& command) {
  SerialBT.println(command);
  Serial.println(command);
}

// Read an analog axis with hysteresis
int updateAxis(int value, int currentDirection) {

  if (currentDirection == 0) {
    if (value < LOW_THRESHOLD) {
      return -1;
    }

    if (value > HIGH_THRESHOLD) {
      return 1;
    }

    return 0;
  }

  if (currentDirection == -1) {
    if (value > HIGH_RELEASE) {
      return 1;
    }

    if (value > LOW_RELEASE) {
      return 0;
    }

    return -1;
  }

  if (currentDirection == 1) {
    if (value < LOW_THRESHOLD) {
      return -1;
    }

    if (value < HIGH_RELEASE) {
      return 0;
    }

    return 1;
  }

  return 0;
}

// Read both joystick axes independently
void readJoystick() {

  int x = analogRead(JOY_X);
  int y = analogRead(JOY_Y);

  xDirection = updateAxis(x, xDirection);
  yDirection = updateAxis(y, yDirection);

  String movement = "MOVE:";

  bool hasDirection = false;

  // X axis
  if (xDirection == -1) {
    movement += "LEFT";
    hasDirection = true;
  }
  else if (xDirection == 1) {
    movement += "RIGHT";
    hasDirection = true;
  }

  // Y axis
  if (yDirection == -1) {
    if (hasDirection) movement += ",";
    movement += "UP";
    hasDirection = true;
  }
  else if (yDirection == 1) {
    if (hasDirection) movement += ",";
    movement += "DOWN";
    hasDirection = true;
  }

  if (!hasDirection) {
    movement += "NONE";
  }

  // Send only when the joystick direction changes
  if (movement != lastMovement) {
    sendCommand(movement);
    lastMovement = movement;
  }
}

// Read four physical buttons
void readButtons() {

  unsigned long now = millis();

  for (int i = 0; i < BUTTON_COUNT; i++) {

    bool reading = digitalRead(buttons[i].pin);

    if (reading != buttons[i].lastReading) {
      buttons[i].lastChange = now;
      buttons[i].lastReading = reading;
    }

    if (now - buttons[i].lastChange >= DEBOUNCE_MS) {

      if (reading != buttons[i].stableState) {

        buttons[i].stableState = reading;

        if (buttons[i].stableState == LOW) {
          sendCommand(buttons[i].command);
        }
      }
    }
  }
}

// Read joystick press switch
void readJoystickSwitch() {

  unsigned long now = millis();
  bool reading = digitalRead(JOY_SW);

  if (reading != lastSWReading) {
    lastSWChange = now;
    lastSWReading = reading;
  }

  if (now - lastSWChange >= DEBOUNCE_MS) {

    if (reading != stableSWState) {

      stableSWState = reading;

      if (stableSWState == LOW) {
        sendCommand("DODGE");
      }
    }
  }
}

void setup() {

  Serial.begin(115200);

  analogReadResolution(12);

  for (int i = 0; i < BUTTON_COUNT; i++) {
    pinMode(buttons[i].pin, INPUT_PULLUP);
  }

  pinMode(JOY_SW, INPUT_PULLUP);

  if (!SerialBT.begin("DungeonExplorer")) {

    Serial.println("Bluetooth startup failed!");

    while (true) {
      delay(1000);
    }
  }

  Serial.println("Dungeon Explorer controller ready!");
  Serial.println("Bluetooth: DungeonExplorer");
  Serial.println("8-direction joystick enabled.");
}

void loop() {

  readJoystick();
  readButtons();
  readJoystickSwitch();

  delay(10);
}
