import serial
from pynput.keyboard import Controller, Key
import time

# Bluetooth outgoing COM port
PORT = "COM8"
BAUD_RATE = 115200

keyboard = Controller()

# Currently held movement keys
held_movement_keys = set()

# Physical joystick direction -> game direction
MOVEMENT_KEYS = {
    "LEFT": Key.up,
    "RIGHT": Key.down,
    "DOWN": Key.left,
    "UP": Key.right,
}

# Physical buttons -> game keyboard keys
BUTTON_KEYS = {
    "SLASH": "x",
    "THRUST": "v",
    "INTERACT": "e",
    "PAUSE": "p",
    "DODGE": Key.shift,
}


def update_movement(directions):

    global held_movement_keys

    # Convert physical directions into game keys
    new_keys = set()

    for direction in directions:

        direction = direction.strip().upper()

        if direction in MOVEMENT_KEYS:
            new_keys.add(MOVEMENT_KEYS[direction])

    # Release keys no longer required
    for key in held_movement_keys - new_keys:
        keyboard.release(key)

    # Press newly required keys
    for key in new_keys - held_movement_keys:
        keyboard.press(key)

    # Update currently held keys
    held_movement_keys = new_keys


def release_all_movement():

    global held_movement_keys

    for key in held_movement_keys:
        keyboard.release(key)

    held_movement_keys.clear()


def press_button(command):

    key = BUTTON_KEYS.get(command)

    if key is None:
        print("Unknown button:", command)
        return

    try:
        keyboard.press(key)
        time.sleep(0.06)

    finally:
        keyboard.release(key)

    print("Button:", command)


def handle_command(command):

    command = command.strip().upper()

    # Movement commands
    if command.startswith("MOVE:"):

        movement = command[5:].strip()

        if movement == "NONE":
            update_movement([])
        else:
            directions = movement.split(",")
            update_movement(directions)

        print("Movement:", movement)

    # Physical button commands
    elif command in BUTTON_KEYS:
        press_button(command)

    else:
        print("Unknown command:", command)


def main():

    print("Connecting to DungeonExplorer on", PORT)

    try:

        with serial.Serial(
            PORT,
            BAUD_RATE,
            timeout=1
        ) as bluetooth:

            time.sleep(1)

            print("Bluetooth connected!")
            print("Focus the Dungeon Explorer game window.")
            print("8-direction joystick control active.")
            print("Press Ctrl+C to exit.")

            while True:

                line = bluetooth.readline().decode(
                    "utf-8",
                    errors="ignore"
                ).strip()

                if line:
                    print("Received:", line)
                    handle_command(line)

    except serial.SerialException as error:

        print("Connection error:", error)
        print("Check Bluetooth pairing and COM8.")
        print("Make sure another program is not using COM8.")

    except KeyboardInterrupt:

        print("\nController stopped.")

    finally:

        release_all_movement()


if __name__ == "__main__":
    main()
