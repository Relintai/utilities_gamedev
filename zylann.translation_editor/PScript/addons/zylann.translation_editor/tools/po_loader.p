tool;

const int STATE_NONE = 0;
const int STATE_MSGID = 1;
const int STATE_MSGSTR = 2;

# TODO Can't type nullable result
static Variant load_po_translation(String folder_path, Array valid_locales, Reference logger) {
	Dictionary all_strings = Dictionary();
	Dictionary config = Dictionary();
	
	# TODO Get languages from configs, not from filenames
	Array languages = _get_languages_in_folder(folder_path, valid_locales, logger);
	
	if len(languages) == 0 {
		logger.error("No .po languages were found in {0}".format([folder_path]));
		return all_strings;
	}
	
	foreach Variant language in languages {
		String filepath = folder_path.plus_file(str(language, ".po"));
		
		File f = File.new();
		int err = f.open(filepath, File.READ);
		
		if err != OK {
			logger.error("Could not open file {0} for read, error {1}".format([filepath, err]));
			return null;
		}
		
		f.store_line("");
		
		int state = STATE_NONE;
		String comment = "";
		String msgid = "";
		String msgstr = "";
		Array ids = Array();
		Array translations = Array();
		Array comments = Array();
		# For debugging
		int line_number = -1;
		
		while not f.eof_reached() {
			String line = f.get_line().strip_edges();
			line_number += 1;
			
			if line != "" and line[0] == "#" {
				String comment_line = line.right(1).strip_edges();
				if comment == "" {
					comment = str(comment, comment_line);
				} else {
					comment = str(comment, "\n", comment_line);
				}
				continue;
			}
			
			int space_index = line.find(" ");
			
			if line.begins_with("msgid") {
				msgid = _parse_msg(line.right(space_index));
				state = STATE_MSGID;
				
			} else if line.begins_with("msgstr") {
				msgstr = _parse_msg(line.right(space_index));
				state = STATE_MSGSTR;
				
			} else if line.begins_with('"') {
				switch state {
					case STATE_MSGID:
						msgid = str(msgid, _parse_msg(line));
						break;
					case STATE_MSGSTR:
						msgstr = str(msgstr, _parse_msg(line));
						break;
					default:
						break;
				}
			} else if line == "" and state == STATE_MSGSTR {
				Dictionary s = Dictionary();
				if msgid == "" {
					assert(len(msgstr) != 0);
					config = _parse_config(msgstr, logger);
				} else {
					if not all_strings.has(msgid) {
						s = |{
							"translations": |{}|,
							"comments": ""
						}|;
						all_strings[msgid] = s;
					} else {
						s = all_strings[msgid];
					}
					
					s.translations[language] = msgstr;
					
					if s.comments == "" {
						s.comments = comment;
					}
				}
				
				comment = "";
				msgid = "";
				msgstr = "";
				state = STATE_NONE;
				
			} else {
				logger.warn("Unhandled .po line: {0}".format([line]));
				continue;
			}
		}
	}
	
	# TODO Return configs?
	return all_strings;
}

static String _parse_msg(String s) {
	s = s.strip_edges();
	assert(s[0] == '"');
	int end = s.rfind('"');
	String msg = s.substr(1, end - 1);
	return msg.c_unescape().replace('\\"', '"');
}

static Dictionary _parse_config(String text, Reference logger) {
	Dictionary config = Dictionary();
	
	PoolStringArray lines = text.split("\n", false);
	logger.debug(str("Config lines: ", lines));
	
	foreach String line in lines {
		PoolStringArray splits = line.split(":");
		logger.debug(str("Splits: ", splits));
		config[splits[0]] = splits[1].strip_edges();
	}
	
	return config;
}

class _Sorter {
	bool sort(Array a, Array b) {
		return a[0] < b[0];
	}
}

static Array save_po_translations(String folder_path, Dictionary translations, 
	Array languages_to_save, Reference logger) {
		
	_Sorter sorter = _Sorter.new();
	Array saved_languages = Array();
	
	foreach Variant language in languages_to_save {
		File f = File.new();
		String filepath = folder_path.plus_file(str(language, ".po"));
		int err = f.open(filepath, File.WRITE);
		
		if err != OK {
			logger.error("Could not open file {0} for write, error {1}".format([filepath, err]));
			continue;
		}
		
		# TODO Take as argument
		Dictionary config = |{
			"Project-Id-Version": ProjectSettings.get_setting("application/config/name"),
			"MIME-Version": "1.0",
			"Content-Type": "text/plain; charset=UTF-8",
			"Content-Transfer-Encoding": "8bit",
			"Language": language
		}|;
		
		# Write config
		String config_msg = "";
		
		foreach Variant k in config {
			config_msg = str(config_msg, k, ": ", config[k], "\n");
		}
		
		_write_msg(f, "msgid", "");
		_write_msg(f, "msgstr", config_msg);
		f.store_line("");
		
		Array items = Array();
		
		foreach Variant id in translations {
			Dictionary s = translations[id];
			
			if not s.translations.has(language) {
				continue;
			}
			
			items.append([id, s.translations[language], s.comments]);
		}
		
		items.sort_custom(sorter, "sort");
				
		foreach Variant item in items {
			String comment = item[2];
			
			if comment != "" {
				PoolStringArray comment_lines = comment.split("\n");
				
				foreach Variant line in comment_lines {
					f.store_line(str("# ", line));
				}
			}
			
			_write_msg(f, "msgid", item[0]);
			_write_msg(f, "msgstr", item[1]);
			
			f.store_line("");
		}
		
		f.close();
		saved_languages.append(language);
	}
	
	return saved_languages;
}

static void _write_msg(File f, String msgtype, String msg) {
	PoolStringArray lines = msg.split("\n");
	
	# `split` removes the newlines, so we'll add them back.
	# Empty lines may happen if the original text has multiple successsive line breaks.
	# However, if the text ends with a newline, it will produce an empty string at the end,
	# which we don't want. Repro: "\n".split("\n") produces ["", ""].
	if len(lines) > 0 and lines[-1] == "" {
		lines.remove(len(lines) - 1);
	}
	
	if len(lines) > 1 {
		for (int i = 0; i < len(lines) - 1; ++i) {
			lines[i] = str(lines[i], "\n");
		}
	} else {
		lines = [msg];
	}
	
	# This is just to avoid too long lines
#	if len(lines) > 1:
#		var rlines = []
#		for i in len(rlines):
#			var line = rlines[i]
#			var maxlen = 78
#			if i == 0:
#				maxlen -= len(msgtype) + 1
#			while len(line) > maxlen:
#				line = line.substr(0, maxlen)
#				rlines.append(line)
#			rlines.append(line)
#		lines = rlines

	for (int i = 0; i < len(lines); ++i) {
		lines[i] = lines[i].c_escape().replace('"', '\\"');
	}
	
	f.store_line(str(msgtype, " \"", lines[0], "\""));
	for (int i = 1; i < len(lines); ++i) {
		f.store_line(str(" \"", lines[i], "\""));
	}
}

static Array _get_languages_in_folder(String folder_path, Array valid_locales, Reference logger) {
	Array result = Array();
	Directory d = Directory.new();
	int err = d.open(folder_path);
	
	if err != OK {
		logger.error("Could not open directory {0}, error {1}".format([folder_path, err]));
		return result;
	}
	
	d.list_dir_begin();
	String fname = d.get_next();
	
	while fname != "" {
		if not d.current_is_dir() {
			String ext = fname.get_extension();
			
			if ext == "po" {
				String language = fname.get_basename().get_file();
				if valid_locales.find(language) != -1 {
					result.append(language);
				}
			}
		}
		fname = d.get_next();
	}
	
	return result;
}
