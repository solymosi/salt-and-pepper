module SaltPepper
	class HashedString
	
		DefaultOptions = { :length => 128 }
		Length = 96..192
		
		attr_reader :hsh, :salt
		
		def initialize(str, options = DefaultOptions)
			raise ArgumentError, "Input must be a String" unless str.is_a?(String)
			options.reverse_merge! DefaultOptions
			HashedString.check_options! options
			@salt = SaltPepper::Random.salt(options[:length])
			@hsh = HashedString.hsh(str, @salt)
		end
		
		def to_s
			""
		end
		
		def to_yaml
			result
		end
		
		def result
			hsh + salt
		end
		
		def inspect
			result.inspect
		end
		
		def ==(obj)
			return self.eql?(obj) if obj.is_a?(HashedString)
			return HashedString.hsh(obj, @salt) == @hsh if obj.is_a?(String)
			false
		end
		
		def eql?(other)
			result == other.result
		end
		
		def set_attributes(h, s)
			@hsh, @salt = h, s
		end
		
		def self.from_hash(h)
			raise ArgumentError, "Hash must be a String or a HashedString" unless h.is_a?(String) || h.is_a?(HashedString)
			h = h.result if h.is_a?(HashedString)
			raise ArgumentError, "Length should be within #{Length.inspect}" unless Length.include?(h.length)
			hs = h[0...64]
			sl = h[64...h.length]
			n = HashedString.new("")
			n.set_attributes(hs, sl)
			n
		end
		
		protected
		
		def self.hsh(password, salt)
			Digest::SHA256.hexdigest(password + salt)
		end
		
		private
		
		def self.check_options!(options)
			options.each do |name, value|
				case name.to_s
					when "length" then
						raise ArgumentError, "Length should be a Fixnum" unless value.is_a?(Fixnum)
						raise ArgumentError, "Length should be within #{Length.inspect}" unless Length.include?(value)
					else
						raise ArgumentError, "Invalid option: #{name.to_s}"
				end
			end
			true
		end

	end
end

class String
	def ==(obj)
		return obj == self if obj.is_a?(SaltPepper::HashedString)
		super
	end
end