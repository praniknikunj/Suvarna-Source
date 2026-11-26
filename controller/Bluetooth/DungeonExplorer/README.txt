SUVARNA BLUETOOTH CONTROLLER
Rishaan Shah's recorded controller. The ESP32 sketch and Python bridge are supplied source.

1. Open the dungeon_explorer_controller folder and flash the .ino onto the Bluetooth Classic-capable ESP32 used for this build.
2. Pair DungeonExplorer in Windows. Find its outgoing Bluetooth serial COM port.
3. Set PORT in dungeon_explorer_controller.py. Rishaan's recorded outgoing port was COM8.
4. Install dependencies with python -m pip install -r requirements.txt.
5. Run python dungeon_explorer_controller.py and focus Suvarna.
6. Stop the bridge with Ctrl+C when done.

Firmware GPIO: joystick X=34, Y=35, press=32. Buttons 25=SLASH, 26=THRUST,
27=INTERACT, 14=PAUSE. All five switches are active-low with internal pull-ups.
The joystick bridge's direction mapping accounts for its orientation.
The portable source ZIP also includes a separate wired reference controller.

Link behavior: the bridge releases held keys when exiting. A silent timeout can leave a key held until input resumes or the bridge closes.
