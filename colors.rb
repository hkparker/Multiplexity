class String
	def colorize(color_code)
		"\e[#{color_code}m#{self}\e[0m"
	end

	def red
		colorize(31)
	end

	def green
		colorize(32)
	end
	
	def yellow
		colorize(33)
	end
	
	def blue
		colorize(34)
	end
	
	def purple
		colorize(35)
	end
	
	def teal
		colorize(36)
	end
	
	def good
		"["+"+".green+"] " + self
	end
	
	def bad
		"["+"-".red+"] " + self
	end	
	
	def question
		"["+"*".purple+"] " + self
	end
	
	def executing
		"Executing: ".red + self
	end
end
