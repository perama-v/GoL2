import time
from enum import Enum
import curses

ModeNames = Enum('Modes', 'INFINITE CREATOR')
key_text = ['1', '2']
mode_keys = [ord(key) for key in key_text]

mode_params = {
    ModeNames.INFINITE: {
        'mode_key': mode_keys[0],
        'button' : key_text[0]
    },
    ModeNames.CREATOR: {
        'mode_key': mode_keys[1],
        'button' : key_text[1]
    }
}

class Keypress:
    # User input during program.
    def __init__(self, starting_key):
        self.key = None
        self.active = True
        self.current_mode = starting_key
        self.mode_changed = False

    def modify_mode(self):
        # Interprets mode selection when a number key is pressed.
        if self.key == self.current_mode:
            self.mode_changed = False
        else:
            self.current_mode = self.key
            self.mode_changed = True

    def read(self, win, data_manager):
        # Reads last key pressed, detects changes.
        self.key = win.getch()
        if self.key == ord('q'):
            self.active = False

        available_mode_keys = [
            mode_params[m]['mode_key']
            for m in data_manager.modes_available
        ]
        # If valid key
        if self.key in mode_keys:
            if self.key in available_mode_keys:
                self.modify_mode()


class Interval:
    # Determines if it is the right time to get data.
    def __init__(self):
        self.sec_since_call = 0
        delay_ms = 2000  # Delay after first window display.
        self.time_msec_after_start = int(time.time()*1000) + delay_ms
        self.time = int(time.time())
        self.ready_to_call_block = False
        # A small delay to allow the interface to appear.
        self.ready_for_startup_data = False
        self.startup_data_done = False

    def reset(self):
        self.time = int(time.time())

    def startup_data_retrieved(self):
        self.ready_for_startup_data = False
        self.startup_data_done = True

    def update(self):
        pass

class DataManager:

    def __init__(self, modes):
        self.all_data = {}
        self.modes_available = [m.name for m in modes]

class Positions:
    # Coordinates of elements, in "(y, x)" where paired.
    def __init__(self, sc, win):
        self.border = 5
        self.get_fixed(sc, win)

    def get_fixed(self, sc, win):
        self.h, self.w = sc.getmaxyx()
        self.y_axis_tip = (self.border, self.border)
        self.y_axis_height = self.h - (2 * self.border) + 1
        self.x_axis_base = (self.h-self.border, self.border)
        self.x_axis_width = self.w - (2 * self.border)



class Mode:
    # The graph context (data, window display)
    # Local 'mode' is a Mode object that configures a display.
    def __init__(self, keypress):
        self.name = get_mode_from_key(keypress)
        # Get unique mode features from global paramater config dict.
        self.params = mode_params[self.name]
        # A list of data dicts with x, y, name, symbol.
        self.data = None
        self.current_block = None

    def prepare_data(self, data_manager):
        # Accepts manager, uses self.params to select and refine.
        # Saves a list of sets of points to be graphed.
        data = data_manager.all_data[self.params['loc_in_manager']]
        self.data = []


def get_mode_from_key(keypress):
    # Returns the ModeName for a given keypress.
    # ord('1') corresponding to the first (default) mode.
    for mode_name in ModeNames:
        if keypress == mode_params[mode_name]['mode_key']:
            return mode_name


def detect_window_and_keypress(win, keypress, data_manager):
    # Reacts to either window being resized or keyboard activity.
    keypress.read(win, data_manager)
    if keypress.key == curses.KEY_RESIZE:
        win.erase()
    if keypress.mode_changed:
        win.erase()
        keypress.mode_changed = False
