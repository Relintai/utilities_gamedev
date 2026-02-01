tool;
extends WindowDialog;

const Script Locales = preload("./locales.p");

signal language_selected(String language);

onready LineEdit _filter_edit = $VBoxContainer/FilterEdit;
onready Tree _languages_list = $VBoxContainer/LanguagesList;
onready Button _ok_button = $VBoxContainer/Buttons/OkButton;

Array _hidden_locales = Array();


void configure(Array hidden_locales) {
	_hidden_locales = hidden_locales;
	_refresh_list();
}

void _refresh_list() {
	_languages_list.clear();
	
	String filter = _filter_edit.text.strip_edges();
	Array locales = Locales.get_all_locales();

	# Hidden root
	_languages_list.create_item();
	
	foreach Array locale in locales {
		if _hidden_locales.find(locale[0]) != -1 {
			continue;
		}
		
		if filter != "" and locale[0].findn(filter) == -1 {
			continue;
		}
		
		TreeItem item = _languages_list.create_item();
		item.set_text(0, locale[0]);
		item.set_text(1, locale[1]);
	}
	
	_ok_button.disabled = true;
}

void _submit() {
	TreeItem item = _languages_list.get_selected();
	emit_signal("language_selected", item.get_text(0));
	hide();
}

void _on_OkButton_pressed() {
	_submit();
}

void _on_CancelButton_pressed() {
	hide();
}

void _on_LanguagesList_item_selected() {
	_ok_button.disabled = false;
}

void _on_LanguagesList_nothing_selected() {
	_ok_button.disabled = true;
}

void _on_LanguagesList_item_activated() {
	_submit();
}

void _on_FilterEdit_text_changed(String new_text) {
	_refresh_list();
}
