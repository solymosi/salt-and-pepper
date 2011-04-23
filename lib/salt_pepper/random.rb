module SaltPepper
	module Random
	
		def self.token(size = 32)
			hex(size)
		end

		def self.code(size = 8, chars = ('A'..'Z').to_a + (0..9).to_a)
			chars = chars.to_a if chars.is_a?(Range)
			chars = chars.chars.to_a.uniq if chars.is_a?(String)
			(1..size).map { chars[self.number(chars.length)] }.join
		end

		def self.numeric_code(size = 8)
			self.code(size, 0..9)
		end

		def self.alpha_code(size = 8)
			self.code(size, 'A'..'Z')
		end

		def self.number(max_or_range)
			return max_or_range.begin + ActiveSupport::SecureRandom.random_number(max_or_range.end - max_or_range.begin + 1) if max_or_range.is_a?(Range)
			ActiveSupport::SecureRandom.random_number(max_or_range)
		end
		
		private
		
		def self.salt(size = DefaultOptions[:length])
			hex(size - 64)
		end
		
		def self.hex(size)
			ActiveSupport::SecureRandom.hex(size / 2)
		end

	end
	
	(Random.methods(false) - Random.private_methods(false)).each do |m|
		module_eval <<-EVAL, __FILE__, __LINE__
			def self.#{m}(*args)
				Random.#{m}(*args)
			end
		EVAL
	end
end