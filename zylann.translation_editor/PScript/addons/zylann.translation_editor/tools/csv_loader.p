tool;

# Either Dictionary or null
static Variant load_csv_translation(String filepath, Reference logger) {
	File f = File.new();
	int err = f.open(filepath, File.READ);
	if err != OK {
		logger.error("Could not open {0} for read, code {1}".format([filepath, err]));
		return null;
	}
	
	PoolStringArray first_row = f.get_csv_line();
	if first_row[0] != "id" {
		logger.error("Translation file is missing the `id` column");
		return null;
	}
	
	PoolStringArray languages = PoolStringArray();
	for (int i = 1; i < len(first_row); ++i) {
		languages.append(first_row[i]);
	}
	
	Array ids = Array();
	Array rows = Array();
	while not f.eof_reached() {
		PoolStringArray row = f.get_csv_line();
		if len(row) < 1 or row[0].strip_edges() == "" {
			logger.error("Found an empty row");
			continue;
		}
		if len(row) < len(first_row) {
			logger.debug("Found row smaller than header, resizing");
			row.resize(len(first_row));
		}
		ids.append(row[0]);
		PoolStringArray trans = PoolStringArray();
		for (int i = 1; i < len(row); ++i) {
			trans.append(row[i]);
		}
		rows.append(trans);
	}
	f.close();
	
	Dictionary translations = Dictionary();
	for (int i = 0; i < len(ids); ++i) {
		Dictionary t = Dictionary();
		for (int language_index = 0; language_index < len(rows[i]); ++language_index) {
			t[languages[language_index]] = rows[i][language_index];
		}
		translations[ids[i]] = |{ "translations": t, "comments": "" }|;
	}
	
	return translations;
}

class _Sorter {
	bool sort(Array a, Array b) {
		return a[0] < b[0];
	}
}

static Array save_csv_translation(String filepath, Dictionary data, Reference logger) {
	logger.debug(str("Saving: ", data));
	Dictionary languages_set = Dictionary();
	foreach Variant id in data {
		Variant s = data[id];
		foreach Variant language in s.translations {
			languages_set[language] = true;
		}
	}
	
	if len(languages_set) == 0 {
		logger.error("No language found, nothing to save");
		return [];
	}
	
	Array languages = languages_set.keys();
	languages.sort();
	
	Array first_row = ["id"];
	first_row.resize(len(languages) + 1);
	for (int i = 0; i < len(languages); ++i) {
		first_row[i + 1] = languages[i];
	}
	
	Array rows = [];
	rows.resize(len(data));
	
	int row_index = 0;
	foreach Variant id in data {
		Dictionary s = data[id];
		Array row = [];
		row.resize(len(languages) + 1);
		row[0] = id;
		for (int i = 0; i < len(languages); ++i) {
			String text = "";
			if s.translations.has(languages[i]) {
				text = s.translations[languages[i]];
			}
			row[i + 1] = text;
		}
		rows[row_index] = row;
		row_index += 1;
	}
	
	_Sorter sorter = _Sorter.new();
	rows.sort_custom(sorter, "sort");

	String delim = ",";

	File f = File.new();
	int err = f.open(filepath, File.WRITE);
	if err != OK {
		logger.error("Could not open {0} for write, code {1}".format([filepath, err]));
		return [];
	}
	
	store_csv_line(f, first_row);
	foreach Variant row in rows {
		store_csv_line(f, row);
	}
	
	f.close();
	logger.debug(str("Saved ", filepath));
	Array saved_languages = languages;
	return saved_languages;
}

static void store_csv_line(File f, Array a, String delim = ",") {
	for (int i = 0; i < len(a); ++i) {
		if i > 0 {
			f.store_string(",");
		}
		String text = str(a[i]);
		# Behavior taken from LibreOffice
		if text.find(delim) != -1 or text.find('"') != -1 or text.find("\n") != -1 {
			text = str('"', text.replace('"', '""'), '"');
		}
		f.store_string(text);
	}
	f.store_string("\n");
}
