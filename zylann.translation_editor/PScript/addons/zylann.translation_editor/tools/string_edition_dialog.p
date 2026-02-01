tool;
extends WindowDialog;

signal submitted(String str_id, String prev_str_id);

onready LineEdit _line_edit = $VBoxContainer/LineEdit;
onready Button _ok_button = $VBoxContainer/Buttons/OkButton;
onready Label _hint_label = $VBoxContainer/HintLabel;

FuncRef _validator_func = null;
String _prev_str_id = "";


void set_replaced_str_id(String str_id) {
	_prev_str_id = str_id;
	_line_edit.text = str_id;
}

void set_validator(FuncRef f) {
	_validator_func = f;
}

void _notification(int what) {
	if what == NOTIFICATION_VISIBILITY_CHANGED {
		if visible {
			if _prev_str_id == "" {
				window_title = "New string ID";
			} else {
				window_title = str("Replace `", _prev_str_id, "`");
			}
			
			_line_edit.grab_focus();
			_validate();
		}
	}
}

void _on_LineEdit_text_changed(String new_text) {
	_validate();
}

void _validate() {
	String new_text = _line_edit.text.strip_edges();
	bool valid = not new_text.empty();
	String hint_message = "";

	if _validator_func != null {
		Variant res = _validator_func.call_func(new_text);
		assert(typeof(res) == TYPE_BOOL or typeof(res) == TYPE_STRING);
		
		if typeof(res) != TYPE_BOOL or res == false {
			hint_message = res;
			valid = false;
		}
	}
	
	_ok_button.disabled = not valid;
	_hint_label.text = hint_message;
	# Note: hiding the label would shift up other controls in the container
}

void _on_LineEdit_text_entered(String new_text) {
	_submit();
}

void _on_OkButton_pressed() {
	_submit();
}

void _on_CancelButton_pressed() {
	hide();
}

void _submit() {
	String s = _line_edit.text.strip_edges();
	emit_signal("submitted", s, _prev_str_id);
	hide();
}
