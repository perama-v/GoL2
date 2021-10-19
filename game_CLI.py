import curses
import time
import asyncio
from game_CLI_utils.manager import *
from game_CLI_utils.network import *

def draw_grid(win, pos, mode):

    return

def offer_modes(win, pos, mode, data_manager):
    # Shows the buttons that a user can press to select mode.
    current_button = mode_params[mode.name]['button']
    available = [
        mode_params[m]['button']
        for m in data_manager.modes_available
    ]
    highlighted = [
        f'[{m}]' if m == current_button else m
        for m in available
    ]
    mode_str = f'Modes: {" ".join(highlighted)}. '
    mode_str += 'Press num key or q to quit.'
    win.addstr(1, pos.w // 2 - len(mode_str)//2, mode_str)


def draw_game(sc, win, mode, data_manager):
    # Gets positions of elements for the current mode, draws.
    pos = Positions(sc, win)
    if pos.w < pos.border * 12 or pos.h < pos.border * 2:
        msg = f'smol window'
        win.addstr(pos.h // 2, pos.w // 2 - len(msg) // 2, msg)
        return
    offer_modes(win, pos, mode, data_manager)
    if mode.data is None or len(mode.data[0]['x_list']) == 0:
        msg = f'Fetching data ...'
        win.addstr(pos.h // 2, pos.w // 2 - len(msg) // 2, msg)
        return

    # TODO: If user has no account, set one up.

    draw_grid(win, pos, mode)
    #draw_axes(win, pos, mode)
    return


def cycle(sc, win, keypress, interval, modes, data_manager):
    # Performs one draw window cycle.
    interval.update()
    detect_window_and_keypress(win, keypress, data_manager)
    # Get mode define by keyboard number input.
    mode = modes[mode_keys.index(keypress.current_mode)]

    draw_game(sc, win, mode, data_manager)
    return keypress.active


def main(sc):
    # Creates a curses window in terminal and main tracking objects,
    # starts rendering in a loop that reacts to keypresses.
    h, w = sc.getmaxyx()
    win = curses.newwin(h, w, 0, 0)
    win.keypad(1)
    curses.curs_set(0)
    interval = Interval()
    modes = [Mode(key) for key in mode_keys]
    data_manager = DataManager(modes)
    keypress = Keypress(mode_keys[0])
    # Begin main display loop.
    active = True
    while active:
        win.border(0)
        win.timeout(100)
        active = cycle(sc, win, keypress, interval, modes,
            data_manager)

    # Close program.
    h, w = sc.getmaxyx()
    sc.refresh()
    time.sleep(3)
    curses.endwin()


if __name__=="__main__":
    curses.wrapper(main)