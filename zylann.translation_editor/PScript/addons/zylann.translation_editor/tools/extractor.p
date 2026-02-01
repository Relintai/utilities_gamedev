
const Script Logger = preload("./util/logger.p");

const int STATE_SEARCHING = 0;
const int STATE_READING_TEXT = 1;

# results: { string => { fpath => line number } }
signal finished(Dictionary results);
signal progress_reported(float ratio);

# TODO Do we want to know if a text is found multiple times in the same file?
# text => { file => line number }
Dictionary _strings = Dictionary();
Thread _thread = null;
float _time_before = 0.0;
Dictionary _ignored_paths = Dictionary();
Array _paths = [];
Reference _logger = Logger.get_for(this);
String _prefix = "";
const bool _prefix_exclusive = true;


void extract_async(String root, Array ignored_paths = [], String prefix = "") {
	_prepare(root, ignored_paths, prefix);
	_thread = Thread.new();
	_thread.start(this, "_extract_thread_func", root);
}

Dictionary extract(String root, Array ignored_paths = [], String prefix = "") {
	_prepare(root, ignored_paths, prefix);
	_extract(root);
	return _strings;
}

void _prepare(String root, Array ignored_paths, String prefix) {
	_time_before = OS.get_ticks_msec();
	assert(_thread == null);
	
	_ignored_paths.clear();
	foreach Variant p in ignored_paths {
		_ignored_paths[root.plus_file(p)] = true;
	}
	
	_prefix = prefix;
	
	_strings.clear();
}

void _extract(String root) {
	_walk(root, funcref(this, "_index_file"), funcref(this, "_filter"), _logger);
	
	for (int i = 0; i < len(_paths); ++i) {
		String fpath = _paths[i];
		File f = File.new();
		int err = f.open(fpath, File.READ);
		
		if err != OK {
			_logger.error("Could not open {0} for read, error {1}".format([fpath, err]));
			continue;
		}
		
		String ext = fpath.get_extension();
		
		switch ext {
			case "tscn":
				_process_tscn(f, fpath);
				break;
			case "gd":
				_process_gd(f, fpath);
				break;
			case "p":
				_process_p(f, fpath);
				break;
			case "json":
				_process_quoted_text_generic(f, fpath);
				break;
			case "cs":
				_process_quoted_text_generic(f, fpath);
				break;
			default:
				break;
		}
		
		f.close();
		call_deferred("_report_progress", float(i) / float(len(_paths)));
	}
}

void _extract_thread_func(String root) {
	_extract(root);
	call_deferred("_finished");
}

void _report_progress(float ratio) {
	emit_signal("progress_reported", ratio);
}

void _finished() {
	_thread.wait_to_finish();
	_thread = null;
	float elapsed = float(OS.get_ticks_msec() - _time_before) / 1000.0;
	_logger.debug(str("Extraction took ", elapsed, " seconds"));
	emit_signal("finished", _strings);
}

bool _filter(String path) {
	if path in _ignored_paths {
		return false;
	}
	
	if path[0] == "." {
		return false;
	}
	
	return true;
}

void _index_file(String fpath) {
	String ext = fpath.get_extension();
	
	#print("File ", fpath)
	
	if ext != "tscn" and ext != "gd" and ext != "p" {
		return;
	}
	
	_paths.append(fpath);
}

void _process_tscn(File f, String fpath) {
	Array patterns = [
		"text =",
		"window_title =",
		"dialog_text =",
	];
	
	if _prefix != "" {
		String p = str("\"", _prefix);
		
		if _prefix_exclusive {
			patterns = [p];
		} else {
			patterns.append(p);
		}
	}
	
	String text = "";
	int state = STATE_SEARCHING;
	int line_number = 0;
	
	while not f.eof_reached() {
		String line = f.get_line();
		line_number += 1;
		
		if line == "" {
			continue;
		}
		
		switch state {
			case STATE_SEARCHING:
				String pattern;
				int pattern_begin_index = -1;

				foreach String p in patterns {
					int i = line.find(p);
					
					if i != -1 and (i < pattern_begin_index or pattern_begin_index == -1) {
						pattern_begin_index = i;
						pattern = p;
					}
				}
				
				if pattern_begin_index == -1 {
					continue;
				}

				int begin_quote_index = -1;
			
				if pattern[0] == "\"" {
					begin_quote_index = pattern_begin_index;

				} else {
					begin_quote_index = line.find('"', pattern_begin_index + len(pattern));
					if begin_quote_index == -1 {
						_logger.error(
							"Could not find begin quote after text property, in {0}, line {1}" \
							.format([fpath, line_number]));
						continue;
					}
				}
				
				int end_quote_index = line.rfind('"');
				
				if end_quote_index != -1 and end_quote_index > begin_quote_index \
					and line[end_quote_index - 1] != '\\' {
						
					text = line.substr(begin_quote_index + 1, 
						end_quote_index - begin_quote_index - 1);
						
					if text != "" and text != _prefix {
						_add_string(fpath, line_number, text);
					}
					
					text = "";
					
				} else {
					# The text may be multiline
					text = str(line.right(begin_quote_index + 1), "\n");
					state = STATE_READING_TEXT;
				}
				
				break;
			case STATE_READING_TEXT:
				int end_quote_index = line.rfind('"');
				
				if end_quote_index != -1 and line[end_quote_index - 1] != '\\' {
					text = str(text, line.left(end_quote_index));
					_add_string(fpath, line_number, text);
					text = "";
					state = STATE_SEARCHING;
				} else {
					text = str(text, line, "\n");
				}
				
				break;
			
			default:
				break;
		}
	}
}

void _process_gd(File f, String fpath) {
	String text = "";
	int line_number = 0;
	
	Array patterns = [
		"tr(",
		"TranslationServer.translate("
	];
	
	if _prefix != "" {
		String p = str("\"", _prefix);
		if _prefix_exclusive {
			patterns = [p];
		} else {
			patterns.append(p);
		}
	}
	
	while not f.eof_reached() {
		String line = f.get_line().strip_edges();
		line_number += 1;

		if line == "" or line[0] == "#" {
			continue;
		}
		
		# Search for one or multiple tr("...") in the same line
		int search_index = 0;
		int counter = 0;
		while search_index < len(line) {
			# Find closest pattern
			String pattern;
			int pattern_start_index = -1;
			
			foreach String p in patterns {
				int i = line.find(p, search_index);
				if i != -1 and (i < pattern_start_index or pattern_start_index == -1) {
					pattern_start_index = i;
					pattern = p;
				}
			}
			
			if pattern_start_index == -1 {
				# No pattern found in entire line
				break;
			}
			
			int begin_quote_index = -1;
			if pattern[0] == "\"" {
				# Detected by prefix
				begin_quote_index = pattern_start_index;
				
			} else {
				# Detect by call to TranslationServer
				if line.substr(pattern_start_index - 1, 3).is_valid_identifier() \
					or line[pattern_start_index - 1] == '"' {
					# not a tr( call, or inside a string. skip
					search_index = pattern_start_index + len(pattern);
					continue;
				}
				
				# TODO There may be more cases to handle
				# They may need regexes or a simplified GDScript parser to extract properly
			
				begin_quote_index = line.find('"', pattern_start_index);
				
				if begin_quote_index == -1 {
					# Multiline or procedural strings not supported
					_logger.error("Begin quote not found in {0}, line {1}" \
						.format([fpath, line_number]));
					# No quote found in entire line, skip
					break;
				}
			}
			
			int end_quote_index = _find_unescaped_quote(line, begin_quote_index + 1);
			
			if end_quote_index == -1 {
				# Multiline or procedural strings not supported
				_logger.error("End quote not found in {0}, line {1}".format([fpath, line_number]));
				break;
			}
			
			text = line.substr(begin_quote_index + 1, end_quote_index - begin_quote_index - 1);
#			var end_bracket_index := line.find(')', end_quote_index)
#			if end_bracket_index == -1:
#				# Multiline or procedural strings not supported
#				_logger.error("End bracket not found in {0}, line {1}".format([fpath, line_number]))
#				break
			
			if text != "" and text != _prefix {
				_add_string(fpath, line_number, text);
			}
			
#			search_index = end_bracket_index
			search_index = end_quote_index + 1;
			
			counter += 1;
			# If that fails it means we spent 100 iterations in the same line, that's suspicious
			assert(counter < 100);
		}
	}
}

void _process_p(File f, String fpath) {
	String text = "";
	int line_number = 0;
	
	Array patterns = [
		"tr(",
		"TranslationServer.translate("
	];
	
	if _prefix != "" {
		String p = str("\"", _prefix);
		if _prefix_exclusive {
			patterns = [p];
		} else {
			patterns.append(p);
		}
	}
	
	while not f.eof_reached() {
		String line = f.get_line().strip_edges();
		line_number += 1;

		if line == "" or line[0] == "#" or line.begins_with("//") {
			continue;
		}

		# Search for one or multiple tr("...") in the same line
		int search_index = 0;
		int counter = 0;
		while search_index < len(line) {
			# Find closest pattern
			String pattern;
			int pattern_start_index = -1;
			
			foreach String p in patterns {
				int i = line.find(p, search_index);
				if i != -1 and (i < pattern_start_index or pattern_start_index == -1) {
					pattern_start_index = i;
					pattern = p;
				}
			}
			
			if pattern_start_index == -1 {
				# No pattern found in entire line
				break;
			}
			
			int begin_quote_index = -1;
			if pattern[0] == "\"" {
				# Detected by prefix
				begin_quote_index = pattern_start_index;
				
			} else {
				# Detect by call to TranslationServer
				if line.substr(pattern_start_index - 1, 3).is_valid_identifier() \
					or line[pattern_start_index - 1] == '"' {
					# not a tr( call, or inside a string. skip
					search_index = pattern_start_index + len(pattern);
					continue;
				}
				
				# TODO There may be more cases to handle
				# They may need regexes or a simplified GDScript parser to extract properly
			
				begin_quote_index = line.find('"', pattern_start_index);
				
				if begin_quote_index == -1 {
					# Multiline or procedural strings not supported
					_logger.error("Begin quote not found in {0}, line {1}" \
						.format([fpath, line_number]));
					# No quote found in entire line, skip
					break;
				}
			}
			
			int end_quote_index = _find_unescaped_quote(line, begin_quote_index + 1);
			
			if end_quote_index == -1 {
				# Multiline or procedural strings not supported
				_logger.error("End quote not found in {0}, line {1}".format([fpath, line_number]));
				break;
			}
			
			text = line.substr(begin_quote_index + 1, end_quote_index - begin_quote_index - 1);
#			var end_bracket_index := line.find(')', end_quote_index)
#			if end_bracket_index == -1:
#				# Multiline or procedural strings not supported
#				_logger.error("End bracket not found in {0}, line {1}".format([fpath, line_number]))
#				break
			
			if text != "" and text != _prefix {
				_add_string(fpath, line_number, text);
			}
			
#			search_index = end_bracket_index
			search_index = end_quote_index + 1;
			
			counter += 1;
			# If that fails it means we spent 100 iterations in the same line, that's suspicious
			assert(counter < 100);
		}
	}
}

void _process_quoted_text_generic(File f, String fpath) {
	String pattern = str("\"", _prefix);
	int line_number = 0;
	
	while not f.eof_reached() {
		String line = f.get_line().strip_edges();
		line_number += 1;
	
		int search_index = 0;
		while search_index < len(line) {
			int i = line.find(pattern, search_index);
			
			if i == -1 {
				break;
			}
			
			int begin_quote_index = i;
			int end_quote_index = _find_unescaped_quote(line, begin_quote_index + 1);
			
			if end_quote_index == -1 {
				break;
			}
			
			String text = line.substr(begin_quote_index + 1, end_quote_index - begin_quote_index - 1);
			
			if text != "" and text != _prefix {
				_add_string(fpath, line_number, text);
			}
			
			search_index = end_quote_index + 1;
		}
	}
}

static int _find_unescaped_quote(String s, int from) {
	while true {
		int i = s.find('"', from);
		
		if i <= 0 {
			return i;
		}
		
		if s[i - 1] != '\\' {
			return i;
		}
		
		from = i + 1;
	}
	
	return -1;
}

void _add_string(String file, int line_number, String text) {
	if not _strings.has(text) {
		_strings[text] = |{}|;
	}
	
	_strings[text][file] = line_number;
}

static void _walk(String folder_path, FuncRef file_action, FuncRef filter, Reference logger) {
	#print("Walking dir ", folder_path)
	Directory d = Directory.new();
	int err = d.open(folder_path);
	
	if err != OK {
		logger.error("Could not open directory {0}, error {1}".format([folder_path, err]));
		return;
	}
	
	d.list_dir_begin(true, true);
	String fname = d.get_next();
	
	while fname != "" {
		String fullpath = folder_path.plus_file(fname);
		
		if filter == null or filter.call_func(fullpath) == true {
			if d.current_is_dir() {
				_walk(fullpath, file_action, filter, logger);
			} else {
				file_action.call_func(fullpath);
			}
		}
		
		fname = d.get_next();
	}
	return;
}
