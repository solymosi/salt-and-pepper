module SaltPepper

	DefaultOptions = { :length => 128 }
	DefaultModelOptions = { :length => DefaultOptions[:length], :skip_blank => true }
	Length = 96..192

	def self.encrypt(password, options = DefaultOptions)
		options.reverse_merge! DefaultOptions
		check_options_for_encrypt options
		salt = self.random_salt(options[:length])
		self.do_hash(password, salt) + salt
	end

	def self.verify(password, hashed_password)
		self.do_hash(password, self.get_salt(hashed_password)) == self.get_hash(hashed_password)
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
	
	def self.check_options_for_encrypt(options)
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
	
	def self.random_salt(size = DefaultOptions[:length])
		random_hex(size - 64)
	end
	
	def self.random_hex(size)
		SecureRandom.hex(size / 2)
	end
	
	def self.do_hash(password, salt)
		Digest::SHA256.hexdigest("#{password}:#{salt}")
	end
	
	def self.get_hash(hashed_password)
		hashed_password[0...64]
	end

	def self.get_salt(hashed_password)
		hashed_password[64...hashed_password.length]
	end


	module ModelExtensions
		module ClassMethods
			def encrypted_attributes
				read_inheritable_attribute :encrypted_attributes
			end
		
			def encrypt(*args)
				options = args.extract_options!
				options.keys.each { |k| raise ArgumentError, "Invalid option: #{k.to_s}" unless DefaultModelOptions.keys.include?(k.to_sym) }
				raise ArgumentError, "No columns specified" if args.empty?
				args.each do |arg|
					raise ArgumentError, "Column name should be a symbol or a string" unless arg.is_a?(String) || arg.is_a?(Symbol)
					raise ArgumentError, "'#{arg.to_s}' is not a valid column name" unless self.column_names.include?(arg.to_s)
					
					write_inheritable_hash(:encrypted_attributes, { arg.to_sym => options.symbolize_keys.reverse_merge(DefaultModelOptions) })
					
					self.class_eval <<-EVAL
						def #{arg.to_s}_is?(check)
							SaltPepper::verify(check, self.#{arg.to_s} || "")
						end
						def validate_#{arg.to_s}?
							currently_plaintext?("#{arg.to_s}")
						end
						def #{arg.to_s}_cleartext
							currently_plaintext?("#{arg.to_s}") ? (read_attribute(:#{arg.to_s}) || "") : ""
						end
					EVAL
				end
				if !self._save_callbacks.map { |c| c.filter.to_sym }.include?(:encrypt_columns_before_save)
					self.before_save :encrypt_columns_before_save
				end
			end

		end

		def self.included(klass)
			klass.extend(ClassMethods)
			klass.write_inheritable_hash(:encrypted_attributes, {})
		end
		
		private
		
		def encrypt_columns_before_save
			self.class.encrypted_attributes.each do |column, options|
				if currently_plaintext?(column)
					if options[:skip_blank]
						encrypt_column(column, options) unless self[column.to_s].blank?
						if self[column.to_s].blank?
							self[column.to_s] = self.changes[column.to_s].first unless self.changes[column.to_s].nil?
						end
					else
						self[column.to_s] = "" if self[column.to_s].nil?
						encrypt_column(column, options)
					end
				end
			end
		end
		
		def encrypt_column(column, options)
			write_attribute(column.to_sym, SaltPepper::encrypt(read_attribute(column.to_sym), { :length => options[:length] }))
		end
		
		def currently_plaintext?(column)
			read_attribute(column.to_sym).blank? || self.new_record? || self.changes.keys.include?(column.to_s)
		end

	end
	
	class ArgumentError < ArgumentError; end
	
end

ActiveSupport.on_load :active_record do
	class ActiveRecord::Base
		include SaltPepper::ModelExtensions
	end
end