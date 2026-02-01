tool;
extends Panel;

const Script CsvLoader = preload("./csv_loader.p");
const Script PoLoader = preload("./po_loader.p");
const Script Locales = preload("./locales.p");
const Script StringEditionDialog = preload("./string_edition_dialog.p");
const Script LanguageSelectionDialog = preload("./language_selection_dialog.p");
const Script ExtractorDialog = preload("./extractor_dialog.p");
const Script Util = preload("./util/util.p");
const Script Logger = preload("./util/logger.p");

const PackedScene StringEditionDialogScene = preload("./string_edition_dialog.tscn");
const PackedScene LanguageSelectionDialogScene = preload("./language_selection_dialog.tscn");
const PackedScene ExtractorDialogScene = preload("./extractor_dialog.tscn");

const int MENU_FILE_OPEN = 0;
const int MENU_FILE_SAVE = 1;
const int MENU_FILE_SAVE_AS_CSV = 2;
const int MENU_FILE_SAVE_AS_PO = 3;
const int MENU_FILE_ADD_LANGUAGE = 4;
const int MENU_FILE_REMOVE_LANGUAGE = 5;
const int MENU_FILE_EXTRACT = 6;

const int FORMAT_CSV = 0;
const int FORMAT_GETTEXT = 1;

const int STATUS_UNTRANSLATED = 0;
const int STATUS_PARTIALLY_TRANSLATED = 1;
const int STATUS_TRANSLATED = 2;

onready MenuButton _file_menu = $VBoxContainer/MenuBar/FileMenu;
onready MenuButton _edit_menu = $VBoxContainer/MenuBar/EditMenu;
onready LineEdit _search_edit = $VBoxContainer/Main/LeftPane/Search/Search;
onready Button _clear_search_button = $VBoxContainer/Main/LeftPane/Search/ClearSearch;
onready ItemList _string_list = $VBoxContainer/Main/LeftPane/StringList;
onready TabContainer _translation_tab_container = \
	$VBoxContainer/Main/RightPane/VSplitContainer/TranslationTabContainer;
onready TextEdit _notes_edit = \
	$VBoxContainer/Main/RightPane/VSplitContainer/VBoxContainer/NotesEdit;
onready Label _status_label = $VBoxContainer/StatusBar/Label;
onready CheckBox _show_untranslated_checkbox = $VBoxContainer/MenuBar/ShowUntranslated;

StringEditionDialog _string_edit_dialog = null;
LanguageSelectionDialog _language_selection_dialog = null;
ConfirmationDialog _remove_language_confirmation_dialog = null;
ConfirmationDialog _remove_string_confirmation_dialog = null;
ExtractorDialog _extractor_dialog = null;
FileDialog _open_dialog = null;
FileDialog _save_file_dialog = null;
FileDialog _save_folder_dialog = null;
# This is set when integrated as a Godot plugin
Control _base_control = null;
# language => TextEdit
Dictionary _translation_edits = Dictionary();
Array _dialogs_to_free_on_exit = Array();
Reference _logger = Logger.get_for(this);
Array _string_status_icons = [null, null, null];

# {string_id => {comments: string, translations: {language_name => text}}}
Dictionary _data = Dictionary();
# string[]
Array _languages = Array();
String _current_path = "";
int _current_format = FORMAT_CSV;
Dictionary _modified_languages = Dictionary();


void _ready() {
	# I don't want any of this to run in the edited scene (because `tool`)...
	if Util.is_in_edited_scene(this) {
		return;
	}
	
	# TODO these icons are blank when running as a game
	_string_status_icons[STATUS_UNTRANSLATED] = get_theme_icon("StatusError", "EditorIcons");
	_string_status_icons[STATUS_PARTIALLY_TRANSLATED] = get_theme_icon("StatusWarning", "EditorIcons");
	_string_status_icons[STATUS_TRANSLATED] = get_theme_icon("StatusSuccess", "EditorIcons");
	
	_file_menu.get_popup().add_item("Open...", MENU_FILE_OPEN);
	_file_menu.get_popup().add_item("Save", MENU_FILE_SAVE);
	_file_menu.get_popup().add_item("Save as CSV...", MENU_FILE_SAVE_AS_CSV);
	_file_menu.get_popup().add_item("Save as PO...", MENU_FILE_SAVE_AS_PO);
	_file_menu.get_popup().add_separator();
	_file_menu.get_popup().add_item("Add language...", MENU_FILE_ADD_LANGUAGE);
	_file_menu.get_popup().add_item("Remove language", MENU_FILE_REMOVE_LANGUAGE);
	_file_menu.get_popup().add_separator();
	_file_menu.get_popup().add_item("Extractor", MENU_FILE_EXTRACT);
	_file_menu.get_popup().set_item_disabled(
		_file_menu.get_popup().get_item_index(MENU_FILE_REMOVE_LANGUAGE), true);
	_file_menu.get_popup().connect("id_pressed", this, "_on_FileMenu_id_pressed");
	
	_edit_menu.get_popup().connect("id_pressed", this, "_on_EditMenu_id_pressed");
	
	# In the editor the parent is still busy setting up children...
	call_deferred("_setup_dialogs");
	
	_update_status_label();
}

void _setup_dialogs() {
	# If this fails, something wrong is happening with parenting of the main view
	assert(_open_dialog == null);
	
	_open_dialog = FileDialog.new();
	_open_dialog.window_title = "Open translations";
	_open_dialog.add_filter("*.csv ; CSV files");
	_open_dialog.add_filter("*.po ; Gettext files");
	_open_dialog.mode = FileDialog.MODE_OPEN_FILE;
	_open_dialog.connect("file_selected", this, "_on_OpenDialog_file_selected");
	_add_dialog(_open_dialog);

	_save_file_dialog = FileDialog.new();
	_save_file_dialog.window_title = "Save translations as CSV";
	_save_file_dialog.add_filter("*.csv ; CSV files");
	_save_file_dialog.mode = FileDialog.MODE_SAVE_FILE;
	_save_file_dialog.connect("file_selected", this, "_on_SaveFileDialog_file_selected");
	_add_dialog(_save_file_dialog);

	_save_folder_dialog = FileDialog.new();
	_save_folder_dialog.window_title = "Save translations as gettext .po files";
	_save_folder_dialog.mode = FileDialog.MODE_OPEN_DIR;
	_save_folder_dialog.connect("dir_selected", this, "_on_SaveFolderDialog_dir_selected");
	_add_dialog(_save_folder_dialog);
	
	_string_edit_dialog = StringEditionDialogScene.instance();
	_string_edit_dialog.set_validator(funcref(this, "_validate_new_string_id"));
	_string_edit_dialog.connect("submitted", this, "_on_StringEditionDialog_submitted");
	_add_dialog(_string_edit_dialog);
	
	_language_selection_dialog = LanguageSelectionDialogScene.instance();
	_language_selection_dialog.connect(
		"language_selected", this, "_on_LanguageSelectionDialog_language_selected");
	_add_dialog(_language_selection_dialog);
	
	_remove_language_confirmation_dialog = ConfirmationDialog.new();
	_remove_language_confirmation_dialog.dialog_text = \
		"Do you really want to remove this language? (There is no undo!)";
	_remove_language_confirmation_dialog.connect(
		"confirmed", this, "_on_RemoveLanguageConfirmationDialog_confirmed");
	_add_dialog(_remove_language_confirmation_dialog);
	
	_extractor_dialog = ExtractorDialogScene.instance();
	_extractor_dialog.set_registered_string_filter(funcref(this, "_is_string_registered"));
	_extractor_dialog.connect("import_selected", this, "_on_ExtractorDialog_import_selected");
	_add_dialog(_extractor_dialog);
	
	_remove_string_confirmation_dialog = ConfirmationDialog.new();
	_remove_string_confirmation_dialog.dialog_text = \
		"Do you really want to remove this string and all its translations? (There is no undo)";
	_remove_string_confirmation_dialog.connect(
		"confirmed", this, "_on_RemoveStringConfirmationDialog_confirmed");
	_add_dialog(_remove_string_confirmation_dialog);
}

void _add_dialog(Control dialog) {
	if _base_control != null {
		_base_control.add_child(dialog);
		_dialogs_to_free_on_exit.append(dialog);
	} else {
		add_child(dialog);
	}
}

void _exit_tree() {
	# Free dialogs because in the editor they might not be child of the main view...
	# Also this code runs in the edited scene view as a `tool` side-effect.
	foreach Node dialog in _dialogs_to_free_on_exit {
		dialog.queue_free();
	}
	
	_dialogs_to_free_on_exit.clear();
}

void configure_for_godot_integration(Control base_control) {
	# You have to call this before adding to the tree
	assert(not is_inside_tree());
	
	_base_control = base_control;
	# Make underlying panel transparent because otherwise it looks bad in the editor
	# TODO Would be better to not draw the panel background conditionally
	self_modulate = Color(0, 0, 0, 0);
}

void _on_FileMenu_id_pressed(int id) {
	switch id {
		case MENU_FILE_OPEN:
			_open();
			break;
		case MENU_FILE_SAVE:
			_save();
			break;
		case MENU_FILE_SAVE_AS_CSV:
			_save_file_dialog.popup_centered_ratio();
			break;
		case MENU_FILE_SAVE_AS_PO:
			_save_folder_dialog.popup_centered_ratio();
			break;
		case MENU_FILE_ADD_LANGUAGE:
			_language_selection_dialog.configure(_languages);
			_language_selection_dialog.popup_centered_ratio();
			break;
		case MENU_FILE_REMOVE_LANGUAGE:
			String language = _get_current_language();
			
			_remove_language_confirmation_dialog.window_title = \
				str("Remove language `", language, "`");
				
			_remove_language_confirmation_dialog.popup_centered_minsize();
			break;
		case MENU_FILE_EXTRACT:
			_extractor_dialog.popup_centered_minsize();
			break;
		default:
			break;
	}
}

void _on_EditMenu_id_pressed(int id) {
	
}

void _on_OpenDialog_file_selected(String filepath) {
	_load_file(filepath);
}

void _on_SaveFileDialog_file_selected(String filepath) {
	_save_file(filepath, FORMAT_CSV);
}

void _on_SaveFolderDialog_dir_selected(String filepath) {
	_save_file(filepath, FORMAT_GETTEXT);
}

void _on_OpenButton_pressed() {
	_open();
}

void _on_SaveButton_pressed() {
	_save();
}

void _on_LanguageSelectionDialog_language_selected(String language) {
	_add_language(language);
}

void _open() {
	_open_dialog.popup_centered_ratio();
}

void _save() {
	if _current_path == "" {
		# Have to default to CSV for now...
		_save_file_dialog.popup_centered_ratio();
	} else {
		_save_file(_current_path, _current_format);
	}
}

void _load_file(String filepath) {
	String ext = filepath.get_extension();
	
	if ext == "po" {
		Array valid_locales = Locales.get_all_locale_ids();
		_current_path = filepath.get_base_dir();
		_data = PoLoader.load_po_translation(_current_path, valid_locales, Logger.get_for(PoLoader));
		_current_format = FORMAT_GETTEXT;
		
	} else if ext == "csv" {
		_data = CsvLoader.load_csv_translation(filepath, Logger.get_for(CsvLoader));
		_current_path = filepath;
		_current_format = FORMAT_CSV;
		
	} else {
		_logger.error("Unknown file format, cannot load {0}".format([filepath]));
		return;
	}
	
	_languages.clear();
	
	foreach Variant strid in _data {
		Dictionary s = _data[strid];
		
		foreach Variant language in s.translations {
			if _languages.find(language) == -1 {
				_languages.append(language);
			}
		}
	}
	
	_translation_edits.clear();
	
	for (int i = 0; i < _translation_tab_container.get_child_count(); ++i) {
		Node child = _translation_tab_container.get_child(i);
		
		if child is TextEdit {
			child.queue_free();
		}
	}
	
	foreach Variant language in _languages {
		_create_translation_edit(language);
	}
	
	_refresh_list();
	_modified_languages.clear();
	_update_status_label();
}

void _update_status_label() {
	if _current_path == "" {
		_status_label.text = "No file loaded";
	} else if _current_format == FORMAT_CSV {
		_status_label.text = _current_path;
	} else if _current_format == FORMAT_GETTEXT {
		_status_label.text = str(_current_path, " (Gettext translations folder)");
	}
}

void _create_translation_edit(String language) {
	assert(not _translation_edits.has(language)); # boom
	TextEdit edit = TextEdit.new();
	edit.hide();
	int tab_index = _translation_tab_container.get_tab_count();
	_translation_tab_container.add_child(edit);
	_translation_tab_container.set_tab_title(tab_index, language);

	String strid = _get_selected_string_id();
	
	if strid != "" {
		Variant s = _data[strid];
		
		if s.translations.has(language) {
			edit.text = s.translations[language];
		}
		
		Variant status = _get_string_status_for_language(strid, language);
		Variant icon = _string_status_icons[status];
		_translation_tab_container.set_tab_icon(tab_index, icon);
	}
	
	_translation_edits[language] = edit;
	edit.connect("text_changed", this, "_on_TranslationEdit_text_changed", [language]);
}

String _get_selected_string_id() {
	PoolIntArray selected = _string_list.get_selected_items();
	
	if len(selected) == 0 {
		return "";
	}
	
	return _string_list.get_item_text(selected[0]);
}

int _get_language_tab_index(String language) {
	Variant page = _translation_edits[language];
	
	for (int i = 0; i < _translation_tab_container.get_child_count(); ++i) {
		if _translation_tab_container.get_child(i) == page {
			return i;
		}
	}
	
	return -1;
}

void _on_TranslationEdit_text_changed(String language) {
	TextEdit edit = _translation_edits[language];
	PoolIntArray selected_strids = _string_list.get_selected_items();
	
	# TODO Don't show the editor if no strings are selected
	if len(selected_strids) != 1 {
		return;
	}

	#assert(len(selected_strids) == 1)
	int list_index = selected_strids[0];
	Variant strid = _string_list.get_item_text(list_index);
	String prev_text;

	Dictionary s = _data[strid];

	if s.translations.has(language) {
		prev_text = s.translations[language];
	}
	
	if prev_text != edit.text {
		s.translations[language] = edit.text;
		_set_language_modified(language);
		
		# Update status icon
		int status = _get_string_status(strid);
		_string_list.set_item_icon(list_index, _string_status_icons[status]);
		
		int tab_index = _get_language_tab_index(language);
		int tab_status = _get_string_status_for_language(strid, language);
		_translation_tab_container.set_tab_icon(tab_index, _string_status_icons[tab_status]);
	}
}

void _on_NotesEdit_text_changed() {
	PoolIntArray selected_strids = _string_list.get_selected_items();
	
	# TODO Don't show the editor if no strings are selected
	if len(selected_strids) != 1 {
		return;
	}
	
	#assert(len(selected_strids) == 1)
	String strid = _string_list.get_item_text(selected_strids[0]);
	Dictionary s = _data[strid];
	
	if s.comments != _notes_edit.text {
		s.comments = _notes_edit.text;
		
		foreach Variant language in _languages {
			_set_language_modified(language);
		}
	}
}

void _set_language_modified(String language) {
	if _modified_languages.has(language) {
		return;
	}
	
	_modified_languages[language] = true;
	_set_language_tab_title(language, str(language, "*"));
}

void _set_language_unmodified(String language) {
	if not _modified_languages.has(language) {
		return;
	}
	
	_modified_languages.erase(language);
	_set_language_tab_title(language, language);
}

void _set_language_tab_title(String language, String title) {
	int tab_index = _get_language_tab_index(language);
	assert(tab_index != -1);
	_translation_tab_container.set_tab_title(tab_index, title);
	# TODO There seem to be a Godot bug, tab titles don't update unless you click on them Oo
	# See https://github.com/godotengine/godot/issues/23696
	_translation_tab_container.update();
}

String _get_current_language() {
	Variant page = _translation_tab_container.get_current_tab_control();
	
	foreach Variant language in _translation_edits {
		if _translation_edits[language] == page {
			return language;
		}
	}
	
	# Something bad happened
	assert(false);
	return "";
}

void _save_file(String path, int format) {
	Array saved_languages = Array();
	
	if format == FORMAT_GETTEXT {
		Array languages_to_save;
		
		if _current_format != FORMAT_GETTEXT {
			languages_to_save = _languages;
		} else {
			languages_to_save = _modified_languages.keys();
		}
		
		saved_languages = PoLoader.save_po_translations(
			path, _data, languages_to_save, Logger.get_for(PoLoader));
		
	} else if format == FORMAT_CSV {
		saved_languages = CsvLoader.save_csv_translation(path, _data, Logger.get_for(CsvLoader));
		
	} else {
		_logger.error("Unknown file format, cannot save {0}".format([path]));
	}
	
	foreach Variant language in saved_languages {
		_set_language_unmodified(language);
	}
	
	_current_format = format;
	_current_path = path;
	_update_status_label();
}

void _refresh_list() {
	PoolIntArray prev_selection = _string_list.get_selected_items();
	String prev_selected_strid = "";
	
	if len(prev_selection) > 0 {
		prev_selected_strid = _string_list.get_item_text(prev_selection[0]);
	}
	
	String search_text = _search_edit.text.strip_edges();
	bool show_untranslated = _show_untranslated_checkbox.pressed;
	
	Array sorted_strids = Array();
	
	foreach Variant strid in _data.keys() {
		if show_untranslated and _get_string_status(strid) == STATUS_TRANSLATED {
			continue;
		}
		
		if search_text != "" and strid.find(search_text) == -1 {
			continue;
		}
		
		sorted_strids.append(strid);
	}
	
	sorted_strids.sort();
	
	_string_list.clear();
	
	foreach Variant strid in sorted_strids {
		int i = _string_list.get_item_count();
		_string_list.add_item(strid);
		int status = _get_string_status(strid);
		Variant icon = _string_status_icons[status];
		_string_list.set_item_icon(i, icon);
	}
	
	# Preserve selection
	if prev_selected_strid != "" {
		for (int i = 0; i < _string_list.get_item_count(); ++i) {
			if _string_list.get_item_text(i) == prev_selected_strid {
				_string_list.select(i);
				# Normally not necessary, unless the list changed a lot
				_string_list.ensure_current_is_visible();
				break;
			}
		}
	}
}

int _get_string_status_for_language(String strid, String language) {
	if len(_languages) == 0 {
		return STATUS_UNTRANSLATED;
	}
	
	Dictionary s = _data[strid];
	
	if not s.translations.has(language) {
		return STATUS_UNTRANSLATED;
	}
	
	String text = s.translations[language].strip_edges();
	
	if text != "" {
		return STATUS_TRANSLATED;
	}
	
	return STATUS_UNTRANSLATED;
}

int _get_string_status(String strid) {
	if len(_languages) == 0 {
		return STATUS_UNTRANSLATED;
	}
	
	Dictionary s = _data[strid];
	int translated_count = 0;
	
	foreach Variant language in s.translations {
		String text = s.translations[language].strip_edges();
		
		if text != "" {
			translated_count += 1;
		}
	}
	
	if translated_count == len(_languages) {
		return STATUS_TRANSLATED;
	}
	
	if translated_count <= 1 {
		return STATUS_UNTRANSLATED;
	}
	
	return STATUS_PARTIALLY_TRANSLATED;
}

void _on_StringList_item_selected(int index) {
	String str_id = _string_list.get_item_text(index);
	Dictionary s = _data[str_id];
	
	foreach Variant language in _languages {
		TextEdit e = _translation_edits[language];
		#e.show()
		if s.translations.has(language) {
			e.text = s.translations[language];
		} else {
			e.text = "";
		}
		
		int status = _get_string_status_for_language(str_id, language);
		Variant icon = _string_status_icons[status];
		int tab_index = _get_language_tab_index(language);
		_translation_tab_container.set_tab_icon(tab_index, icon);
	}
	
	_notes_edit.text = s.comments;
}

void _on_AddButton_pressed() {
	_string_edit_dialog.set_replaced_str_id("");
	_string_edit_dialog.popup_centered();
}

void _on_RemoveButton_pressed() {
	PoolIntArray selected_items = _string_list.get_selected_items();
	
	if len(selected_items) == 0 {
		return;
	}
	
	String str_id = _string_list.get_item_text(selected_items[0]);
	_remove_string_confirmation_dialog.window_title = str("Remove `", str_id, "`");
	_remove_string_confirmation_dialog.popup_centered_minsize();
}

void _on_RemoveStringConfirmationDialog_confirmed() {
	PoolIntArray selected_items = _string_list.get_selected_items();
	
	if len(selected_items) == 0 {
		_logger.error("No selected string??");
		return;
	}
	
	String strid = _string_list.get_item_text(selected_items[0]);
	_string_list.remove_item(selected_items[0]);
	_data.erase(strid);
	
	foreach Variant language in _languages {
		_set_language_modified(language);
	}
}

void _on_RenameButton_pressed() {
	PoolIntArray selected_items = _string_list.get_selected_items();
	
	if len(selected_items) == 0 {
		return;
	}
	
	String str_id = _string_list.get_item_text(selected_items[0]);
	_string_edit_dialog.set_replaced_str_id(str_id);
	_string_edit_dialog.popup_centered();
}

void _on_StringEditionDialog_submitted(String str_id, String prev_str_id) {
	if prev_str_id == "" {
		_add_new_string(str_id);
	} else {
		_rename_string(prev_str_id, str_id);
	}
}

Variant _validate_new_string_id(String str_id) {
	if _data.has(str_id) {
		return "Already existing";
	}
	
	if str_id.strip_edges() != str_id {
		return "Must not start or end with spaces";
	}
	
	foreach Variant k in _data {
		if k.nocasecmp_to(str_id) == 0 {
			return "Already existing with different case";
		}
	}
	
	return true;
}

void _add_new_string(String strid) {
	_logger.debug(str("Adding new string ", strid));
	assert(not _data.has(strid));
	
	Dictionary s = |{
		"translations": |{}|,
		"comments": ""
	}|;
	
	_data[strid] = s;

	foreach Variant language in _languages {
		_set_language_modified(language);
	}
	
	# Update UI
	_refresh_list();
}

void _add_new_strings(Array strids) {
	if len(strids) == 0 {
		return;
	}
	
	foreach Variant strid in strids {
		assert(not _data.has(strid));
		
		Dictionary s = |{
			"translations": |{}|,
			"comments": ""
		}|;
		
		_data[strid] = s;
	}
	
	foreach Variant language in _languages {
		_set_language_modified(language);
	}
	
	# Update UI
	_refresh_list();
}

void _rename_string(String old_strid, String new_strid) {
	assert(_data.has(old_strid));
	
	Dictionary s = _data[old_strid];
	_data.erase(old_strid);
	_data[new_strid] = s;

	foreach Variant language in _languages {
		_set_language_modified(language);
	}
	
	# Update UI
	for (int i = 0; i < _string_list.get_item_count(); ++i) {
		if _string_list.get_item_text(i) == old_strid {
			_string_list.set_item_text(i, new_strid);
			break;
		}
	}
}

void _add_language(String language) {
	assert(_languages.find(language) == -1);
	
	_create_translation_edit(language);
	_languages.append(language);
	_set_language_modified(language);
	
	int menu_index = _file_menu.get_popup().get_item_index(MENU_FILE_REMOVE_LANGUAGE);
	_file_menu.get_popup().set_item_disabled(menu_index, false);
	
	_logger.debug(str("Added language ", language));
	
	_refresh_list();
}

void _remove_language(String language) {
	assert(_languages.find(language) != -1);
	
	_set_language_unmodified(language);
	TextEdit edit = _translation_edits[language];
	edit.queue_free();
	_translation_edits.erase(language);
	_languages.erase(language);

	if len(_languages) == 0 {
		int menu_index = _file_menu.get_popup().get_item_index(MENU_FILE_REMOVE_LANGUAGE);
		_file_menu.get_popup().set_item_disabled(menu_index, true);
	}
	
	_logger.debug(str("Removed language ", language));
	
	_refresh_list();
}

void _on_RemoveLanguageConfirmationDialog_confirmed() {
	String language = _get_current_language();
	_remove_language(language);
}

# Used as callback for filtering
bool _is_string_registered(String text) {
	if _data == null {
		_logger.debug("No data");
		return false;
	}
	
	return _data.has(text);
}

void _on_ExtractorDialog_import_selected(Dictionary results) {
	Array new_strings = Array();
	
	foreach Variant text in results {
		if not _is_string_registered(text) {
			new_strings.append(text);
		}
	}
	
	_add_new_strings(new_strings);
}

void _on_Search_text_changed(String search_text) {
	_clear_search_button.visible = (search_text != "");
	_refresh_list();
}

void _on_ClearSearch_pressed() {
	_search_edit.text = "";
	# LineEdit does not emit `text_changed` when doing this
	_on_Search_text_changed(_search_edit.text);
}

void _on_ShowUntranslated_toggled(bool button_pressed) {
	_refresh_list();
}
