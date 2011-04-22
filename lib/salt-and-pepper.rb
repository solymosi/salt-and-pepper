module SaltPepper
	HashAlgorithms = { :sha1 => [Digest::SHA1, 40], :sha256 => [Digest::SHA256, 64], :sha384 => [Digest::SHA384, 96], :sha512 => [Digest::SHA512, 128], :md5 => [Digest::MD5, 32] }
	DefaultOptions = { :algorithm => :sha256, :salt_size => 64 }
	SaltSize = 16..256

	def self.encrypt(password, options = DefaultOptions)
		salt = self.generate_salt
		self.do_hash(password, salt) + salt
	end

	def self.verify(password, hashed_password, options = DefaultOptions)
		self.do_hash(password, self.get_salt(hashed_password), options) == self.get_hash(hashed_password, options)
	end

	def self.token(size = 32)
		random_hex(size)
	end

	def self.code(size = 8, chars = ('A'..'Z').to_a + (0..9).to_a)
		chars = chars.to_a if chars.is_a?(Range)
		chars = chars.chars.to_a.uniq if chars.is_a?(String)
		(1..size).map { chars[self.random_number(chars.length)] }.join
	end

	def self.numeric_code(size = 8)
		self.code(size, 0..9)
	end

	def self.alpha_code(size = 8)
		self.code(size, 'A'..'Z')
	end

	def self.random_number(max_or_range)
		return max_or_range.begin + SecureRandom.random_number(max_or_range.end - max_or_range.begin + 1) if max_or_range.is_a?(Range)
		SecureRandom.random_number(max_or_range)
	end
	
	private
	
	def self.random_salt(size = DefaultOptions[:salt_size])
		random_hex(size)
	end
	
	def self.random_hex(size)
		SecureRandom.hex(size / 2)
	end
	
	def self.do_hash(password, salt)
		Digest::SHA512.hexdigest("#{password}:#{salt}")
	end
	
	def self.get_hash(hashed_password, options)
		hashed_password[0...(HashAlgorithms[options[:algorithm]].last)]
	end

	def self.get_salt(hashed_password, options)
		start = HashAlgorithms[options[:algorithm]].last
		hashed_password[start...(start + options[:salt_size])]
	end


	module ModelExtensions
		module ClassMethods
			def encrypted_attributes
				read_inheritable_attribute :encrypted_attributes
			end
		
			def encrypt(*args)
				options = args.extract_options!
				check_options_for_encrypt options
				raise ArgumentError, "Encrypt: no columns specified" if args.empty?
				args.each do |arg|
					raise ArgumentError, "Encrypt: column name should be a symbol or a string" unless arg.is_a?(String) || arg.is_a?(Symbol)
					raise ArgumentError, "Encrypt: '#{arg.to_s}' is not a valid column name" unless self.column_names.include?(arg.to_s)
					write_inheritable_hash(:encrypted_attributes, { arg.to_sym => options.symbolize_keys.reverse_merge(DefaultOptions) })
				end
			end
			
			private
			
			def check_options_for_encrypt(options)
				options.each do |k, v|
					case k.to_s
						when "algorithm" then raise ArgumentError, "Encrypt: unsupported algorithm '#{v.to_s}'. Supported: #{HashAlgorithms.keys.inspect}" unless HashAlgorithms.include?(v.to_sym)
						when "salt_size" then
							raise ArgumentError, "Encrypt: salt_size should be a Fixnum" unless v.is_a?(Fixnum)
							raise ArgumentError, "Encrypt: salt_size should be within #{SaltSize.inspect}" unless SaltSize.include?(v)
						else
							raise ArgumentError, "Encrypt: invalid option '#{k.to_s}'"
					end
				end
				true
			end
		end

		def self.included(klass)
			klass.extend(ClassMethods)
			klass.write_inheritable_hash(:encrypted_attributes, {})
		end
	end
	
end

ActiveSupport.on_load :active_record do
	class ActiveRecord::Base
		include SaltPepper::ModelExtensions
	end
end