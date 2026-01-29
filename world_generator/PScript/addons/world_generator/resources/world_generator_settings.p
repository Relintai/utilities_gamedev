tool;
extends Resource;
class_name WorldGeneratorSettings;

export(PoolStringArray) PoolStringArray continent_class_folders;
export(PoolStringArray) PoolStringArray zone_class_folders;
export(PoolStringArray) PoolStringArray subzone_class_folders;
export(PoolStringArray) PoolStringArray subzone_prop_class_folders;

enum WorldGeneratorScriptType {
	CONTINENT = 0,
	ZONE = 1,
	SUBZONE = 2,
	SUBZONE_PROP = 3,
};

void evaluate_scripts(int script_type, Tree tree) {
	if (script_type == WorldGeneratorScriptType.CONTINENT) {
		evaluate_continent_scripts(tree);
	} else if (script_type == WorldGeneratorScriptType.ZONE) {
		evaluate_zone_scripts(tree);
	} else if (script_type == WorldGeneratorScriptType.SUBZONE) {
		evaluate_subzone_scripts(tree);
	} else if (script_type == WorldGeneratorScriptType.SUBZONE_PROP) {
		evaluate_subzone_prop_scripts(tree);
	}
}

void evaluate_continent_scripts(Tree tree) {
	tree.clear();
	
	TreeItem root = tree.create_item();
	root.set_text(0, "Continent");
	root.set_meta("class_name", "Continent");
	
	foreach Variant s in continent_class_folders {
		evaluate_folder(s, tree, root);
	}
	
	root.select(0);
}

void evaluate_zone_scripts(Tree tree) {
	tree.clear();
	
	TreeItem root = tree.create_item();
	root.set_text(0, "Zone");
	root.set_meta("class_name", "Zone");
	
	foreach Variant s in zone_class_folders {
		evaluate_folder(s, tree, root);
	}
	
	root.select(0);
}

void evaluate_subzone_scripts(Tree tree) {
	tree.clear();
	
	TreeItem root = tree.create_item();
	root.set_text(0, "SubZone");
	root.set_meta("class_name", "SubZone");
	
	foreach Variant s in subzone_class_folders {
		evaluate_folder(s, tree, root);
	}
	
	root.select(0);
}

void evaluate_subzone_prop_scripts(Tree tree) {
	tree.clear();
	
	TreeItem root = tree.create_item();
	root.set_text(0, "SubZoneProp");
	root.set_meta("class_name", "SubZoneProp");
	
	foreach Variant s in subzone_prop_class_folders {
		evaluate_folder(s, tree, root);
	}
	
	root.select(0);
}

void evaluate_folder(String folder, Tree tree, TreeItem root) {
	TreeItem ti = null;
	
	Directory dir = Directory.new();
	
	if dir.open(folder) == OK {
		dir.list_dir_begin();
		String file_name = dir.get_next();
		while file_name != "" {
			if !dir.current_is_dir() {
				#print("Found file: " + file_name)
				
				if !ti {
					String n = folder.substr(folder.find_last("/") + 1);
					
					if n != "" {
						ti = tree.create_item(root);
						ti.set_text(0, n);
					} else {
						ti = root;
					}
				}
				
				TreeItem e = tree.create_item(ti);
				
				e.set_text(0, file_name.get_file());
				e.set_meta("file", folder + "/" + file_name);
			}
			
			file_name = dir.get_next();
		}
	} else {
		print("An error occurred when trying to access the path.");
	}
}
