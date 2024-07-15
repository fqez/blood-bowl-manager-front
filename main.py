import threading

from kivy.clock import Clock
from kivy.core.window import Window
from kivy.lang import Builder
from kivymd.app import MDApp
from kivymd.uix.screenmanager import MDScreenManager

from api.api_client import fetch_data
from ui.widgets.cards import PerkCards


class BloodSuperBowl(MDApp):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.sm = MDScreenManager()

    def build(self):
        Window.size = (350, 640)
        Window.clearcolor = (1, 1, 1, 1)
        Builder.load_file("ui/kv/main_widget.kv")
        self.sm.add_widget(PerkCards())
        self.sm.current = "perkcards"
        return self.sm

    def search(self, endpoint):
        threading.Thread(target=self.fetch_and_display_data, args=(endpoint,)).start()

    def fetch_and_display_data(self, endpoint):

        data = fetch_data(endpoint)
        Clock.schedule_once(lambda dt: self.update_result(data))

    def update_result(self, data, error=None):
        if data is not None:
            print(data)

    def reset_button(self):
        self.call_api_btn.disabled = False  # Re-enable the button


if __name__ == "__main__":
    BloodSuperBowl().run()
