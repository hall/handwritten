import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

def one(a, b):
    print("one")
def two(a, b):
    print("two")

w = Gtk.Window()
w.connect('button-press-event', one)
w.connect('button-press-event', two)
w.show()
Gtk.main()

