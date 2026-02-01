tool;
extends WindowDialog;

const Script Extractor = preload("./extractor.p");
const Script Logger = preload("./util/logger.p");

signal import_selected(Dictionary strings);

onready LineEdit _root_path_edit = $VB/HB/RootPathEdit;
onready LineEdit _excluded_dirs_edit = $VB/HB2/ExcludedDirsEdit;
onready LineEdit _prefix_edit = $VB/HB3/PrefixLineEdit;
onready Label _summary_label = $VB/StatusBar/SummaryLabel;
onready Tree _results_list = $VB/Results;
onready ProgressBar _progress_bar = $VB/StatusBar/ProgressBar;
onready Button _extract_button = $VB/Buttons/ExtractButton;
onready Button _import_button = $VB/Buttons/ImportButton;

Extractor _extractor = null;
# { string => { fpath => line number } }
Dictionary _results = Dictionary();
FuncRef _registered_string_filter = null;
Reference _logger = Logger.get_for(this);


void _ready() {
	_import_button.disabled = true;
}

void set_registered_string_filter(FuncRef registered_string_filter) {
	_registered_string_filter = registered_string_filter;
}

void _notification(int what) {
	if what == NOTIFICATION_VISIBILITY_CHANGED {
		if visible {
			_summary_label.text = "";
			_results.clear();
			_results_list.clear();
			_update_import_button();
			
			if ProjectSettings.has_setting("translation_editor/string_prefix") {
				_prefix_edit.text = ProjectSettings.get_setting("translation_editor/string_prefix");
			}
			
			if ProjectSettings.has_setting("translation_editor/search_root") {
				_root_path_edit.text = ProjectSettings.get_setting("translation_editor/search_root");
			}
			
			if ProjectSettings.has_setting("translation_editor/ignored_folders") {
				_excluded_dirs_edit.text = \
					ProjectSettings.get_setting("translation_editor/ignored_folders");
			}
		}
	}
}

void _update_import_button() {
	# Can only import if there are results to import
	_import_button.disabled = (len(_results) == 0);
}

void _on_ExtractButton_pressed() {
	if _extractor != null {
		return;
	}
	
	String root = _root_path_edit.text.strip_edges();
	Directory d = Directory.new();
	
	if not d.dir_exists(root) {
		_logger.error("Directory {0} does not exist".format([root]));
		return;
	}
	
	PoolStringArray excluded_dirs = _excluded_dirs_edit.text.split(";", false);
	
	for (int i = 0; i < len(excluded_dirs); ++i) {
		excluded_dirs[i] = excluded_dirs[i].strip_edges();
	}
	
	String prefix = _prefix_edit.text.strip_edges();
	
	_extractor = Extractor.new();
	_extractor.connect("progress_reported", this, "_on_Extractor_progress_reported");
	_extractor.connect("finished", this, "_on_Extractor_finished");
	_extractor.extract_async(root, excluded_dirs, prefix);
	
	_progress_bar.value = 0;
	_progress_bar.show();
	_summary_label.text = "";
	
	_extract_button.disabled = true;
	_import_button.disabled = true;
}

void _on_ImportButton_pressed() {
	emit_signal("import_selected", _results);
	_results.clear();
	hide();
}

void _on_CancelButton_pressed() {
	# TODO Cancel extraction?
	hide();
}

void _on_Extractor_progress_reported(float ratio) {
	_progress_bar.value = 100.0 * ratio;
}

void _on_Extractor_finished(Dictionary results) {
	_logger.debug("Extractor finished");
	
	_progress_bar.value = 100;
	_progress_bar.hide();
	
	_results_list.clear();
	
	Dictionary registered_set = Dictionary();
	Dictionary new_set = Dictionary();
	
	# TODO We might actually want to not filter, in order to update location comments
	# Filter results
	if _registered_string_filter != null {
		Array texts = results.keys();
		
		foreach String text in texts {
			if _registered_string_filter.call_func(text) {
				results.erase(text);
				registered_set[text] = true;
			}
		}
	}
	
	# Root
	_results_list.create_item();
	
	foreach Variant text in results {
		TreeItem item = _results_list.create_item();
		item.set_text(0, text);
		item.collapsed = true;
		new_set[text] = true;
		
		Variant files = results[text];
		foreach Variant file in files {
			int line_number = files[file];
			
			TreeItem file_item = _results_list.create_item(item);
			file_item.set_text(0, str(file, ": ", line_number));
		}
	}
	
	_results = results;
	_extractor = null;

	_update_import_button();
	_extract_button.disabled = false;
	
	_summary_label.text = "{0} new, {1} registered".format([len(new_set), len(registered_set)]);
}
