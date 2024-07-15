import json
import os

from kivy.clock import Clock
from kivy.metrics import dp
from kivy.properties import StringProperty
from kivy.uix.label import Label
from kivy.uix.modalview import ModalView
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.divider.divider import MDDivider
from kivymd.uix.label import MDLabel
from kivymd.uix.screen import MDScreen
from kivymd.uix.stacklayout import MDStackLayout
from kivymd.uix.textfield import MDTextField

from config.settings import BASE_DIR


class PerkCards(MDScreen):
    pass


class SearchBar(MDTextField):
    pass


class CardsView(MDBoxLayout):

    cards_by_family = dict()

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.search_field = MDTextField(hint_text="Search")
        self.last_search_text = ""
        self.search_field.bind(text=self.schedule_update)
        self.add_widget(self.search_field)
        self.update_trigger = Clock.create_trigger(self.update_view, 0.25)

        with open(f"{BASE_DIR}/assets/data.json") as f:
            data = json.load(f)["data"]

        self.full_data = data
        self.init(data)

    def init(self, data):
        self.cards_by_family.clear()
        for perk in data:
            family = perk["family"]
            self.cards_by_family.setdefault(family, []).append(perk)

        self.update_view()

    def schedule_update(self, instance, value):
        current_text = self.search_field.text
        if current_text != self.last_search_text:  # Verifica si el texto ha cambiado
            self.last_search_text = (
                current_text  # Actualiza el último texto de búsqueda
            )
            self.update_trigger()

    def update_view(self, *args):
        search_text = self.search_field.text.lower()
        filtered_data = [
            perk for perk in self.full_data if search_text in perk["name"]["es"].lower()
        ]

        self.clear_widgets()
        self.add_widget(self.search_field)  # Add the search field back after clearing

        self.cards_by_family.clear()
        for perk in filtered_data:
            family = perk["family"]
            self.cards_by_family.setdefault(family, []).append(perk)

        for family, perks in self.cards_by_family.items():
            self.add_widget(MDLabel(text=family, font_style="Headline", role="small"))
            self.add_widget(MDDivider())
            self.add_widget(Cards(perks))
            self.add_widget(Label(size_hint_y=None, height=dp(30)))


class Cards(MDStackLayout):

    def __init__(self, data, **kwargs):
        super().__init__(**kwargs)
        self.init(data)

    def init(self, data):

        for perk in data:
            title = perk.get("name").get("es")
            description = perk.get("description").get("es")
            id = perk.get("id")
            img = f"{BASE_DIR}/assets/images/perks/upscaled/{id}.png"

            if not os.path.exists(img):
                img = f"{BASE_DIR}/assets/images/perks/upscaled/perk-undefined.png"
            card = Card(
                title=title,
                description=description,
                image=img,
                name=id,
                size_hint=(None, None),
                size=(dp(100), dp(130)),
            )
            self.add_widget(card)


class CardExplanation(ModalView):

    card_title = StringProperty()
    image_source = StringProperty()
    card_description = StringProperty()

    def __init__(self, title, description, img, **kwargs):
        super().__init__(**kwargs)
        self.card_title = title
        self.card_description = description
        self.image_source = img


class Card(MDBoxLayout):

    card_title = StringProperty()
    image_source = StringProperty()
    card_name = StringProperty()

    def __init__(self, title, description, image, name, **kwargs):
        super().__init__(**kwargs)
        self.card_title = title
        self.image_source = image
        self.card_name = name
        self.description = description
        self.card_explanation = CardExplanation(
            self.card_title, self.description, self.image_source
        )

    def on_clicked_card(self):
        print(f"Card {self.card_name} pressed")
        self.card_explanation.open()
