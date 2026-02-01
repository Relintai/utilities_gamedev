
class Base : Reference {
	String _context = "";
	
	void _init(String p_context) {
		_context = p_context;
	}
	
	void debug(String msg) {
	}

	void warn(String msg) {
		push_warning("{0}: {1}".format([_context, msg]));
	}
	
	void error(String msg) {
		push_error("{0}: {1}".format([_context, msg]));
	}
};

class Verbose extends Base {
	void _init(String p_context).(p_context) {
	}

	void debug(String msg) {
		print(_context, ": ", msg);
	}
};

static Base get_for(Object owner) {
	# Note: don't store the owner. If it's a Reference, it could create a cycle
	String context;
	
	if owner is Script {
		context = owner.resource_path.get_file();
	} else {
		context = owner.get_script().resource_path.get_file();
	}
	
	if OS.is_stdout_verbose() {
		return Verbose.new(context);
	}
	
	return Base.new(context);
}
