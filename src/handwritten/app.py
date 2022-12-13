import toga
from toga.style import Pack
from toga.style.pack import COLUMN

import easyocr
import numpy as np
from skimage import draw
from pynput.keyboard import Key, Controller


class Canvas():
    """
    Create drawing canvas in WINDOW
    """
    def __init__(self, window):
        # track last pointer position
        self.x = self.y = None

        # create background representation of image
        self.matrix = np.zeros(tuple(reversed(window.size))).astype(np.uint8)

        self.canvas = toga.Canvas(
            on_press=self.on_press,
            on_drag=self.on_drag,
            on_release=self.on_release,
            # style=Pack(),
        )

        self.box = toga.Box(
            children=[self.canvas], 
            style=Pack(flex=1, direction=COLUMN)
        )

    def on_release(self, widget, x, y, clicks):
        """
        Reset cursor position
        """
        self.x = self.y = None

    def on_drag(self, widget, x, y, clicks):
        """
        Draw a line from the old coordinates to the new ones, X and Y
        """
        # draw a line on the canvas
        with self.canvas.stroke(line_width=2.0) as path:
            with path.closed_path(self.x, self.y) as line:
                line.line_to(x, y)

        # draw a line in the matrix representation
        rr, cc = draw.line(int(self.y), int(self.x), int(y), int(x))
        self.matrix[rr, cc] = 255 # <- full b/w contrast against the existing zeros

        # update saved coordinates
        self.x = x
        self.y = y

    def on_press(self, widget, x, y, clicks):
        """
        Initialize cursor position at X, Y
        """
        self.x = x
        self.y = y
    
    def clear(self):
        """
        Clean canvas and reset data
        """
        self.canvas.clear()
        self.x = self.y = None
        self.matrix *= 0
    
    def read(self):
        """
        Get matrix/image representation
        """
        return self.matrix

class Buttons():
    """
    Collection of buttons
    """
    def __init__(self, canvas, window):
        """
        Create buttons associated to CANVAS in WINDOW
        """
        self.canvas = canvas
        self.window = window

        self.keyboard = Controller()

        # get all supported languages
        # TODO: persist selection (probably solved w/ prefs)
        # TODO: move to preferences (pending toga)
        self.langs = ["en"] + easyocr.config.all_lang_list
        self.reader = easyocr.Reader([self.langs[0]])

        self.style=Pack(padding=0, flex=1)
        self.result = toga.Button("", on_press=self.type, style=self.style)

        self.box = toga.Box(
            style=Pack(direction=COLUMN),
            children=[
                toga.Button("⏎", on_press=self.enter, style=self.style),
                toga.Button("⌫", on_press=self.delete, style=self.style),
                # toga.Button("📍", on_press=self.pin, style=self.style),
                toga.Selection(items=self.langs, on_select=self.language, style=self.style),
                self.result
            ]
        )

    def enter(self, widget):
        """
        Submit canvas for recognition
        """
        result = self.reader.readtext(
            self.canvas.read(),
            detail=0,
            paragraph=True
        )
        if len(result) == 1:
            self.result.text = result[0]
        else:
            self.window.info_dialog('result', " ".join(result))

    def delete(self, widget):
        """
        Reset the canvas
        """
        self.canvas.clear()
        self.result.text = ""

    def type(self, widget):
        """
        Type out the determined result
        """
        self.keyboard.type(self.result.text)

    def language(self, widget):
        """
        Set the detection language
        """
        self.reader = easyocr.Reader([widget.value])

    # def pin(self, widget):
    #     """
    #     Toggle pinning the widow on top of stack
    #     """
    #     pass


class Handwritten(toga.App):
    def startup(self):
        self.main_window = toga.MainWindow(
            title=self.formal_name,
            size=(900,100)
        )
        c = Canvas(self.main_window)
        self.main_window.content = toga.Box(
            children=[
                Buttons(c, self.main_window).box,
                toga.Divider(direction=toga.Divider.VERTICAL),
                c.box,
            ]
        )
        # self.window = toga.Window()
        # self.window.content = toga.Box(children=[
        #     toga.Switch("test")
        # ])

        # self.commands.add(
        #     toga.Command(
        #         lambda widget: self.window.show(),
        #         text="Languages",
        #         group=toga.Group.APP,
        #     )
        # )
        self.main_window.show()


def main():
    return Handwritten()
