module SaltPepper
	module ModelExtensions
	
		DefaultHashColumnOptions = { :length => SaltPepper::HashedString::DefaultOptions[:length], :hash_blank_strings => false }
		
		module ClassMethods
		
			def hashed_columns
				read_inheritable_attribute :hashed_columns
			end
		
			def hash_column(*args)
				options = args.extract_options!
				options.keys.each { |k| raise ArgumentError, "Invalid option: #{k.to_s}" unless DefaultHashColumnOptions.keys.include?(k.to_sym) }
				raise ArgumentError, "No columns specified" if args.empty?
				raise ArgumentError, "Primary key cannot be hashed" if (["id", self.primary_key] - (args.map { |a| a.to_s })).length < 2
				args.each do |arg|
					raise ArgumentError, "Column name should be a symbol or a string" unless arg.is_a?(String) || arg.is_a?(Symbol)
					raise ArgumentError, "'#{arg.to_s}' is not a valid column name" unless self.column_names.include?(arg.to_s)
					
					write_inheritable_hash(:hashed_columns, { arg.to_sym => options.symbolize_keys.reverse_merge(DefaultHashColumnOptions) })
					self.cached_attributes.delete arg.to_s
					
					self.class_eval <<-EVAL
						def validate_#{arg.to_s}?
							!hashed?("#{arg.to_s}")
						end
					EVAL
				end
				if !self._save_callbacks.map { |c| c.filter.to_sym }.include?(:hash_before_save)
					self.before_save :hash_before_save
				end
			end

		end

		def self.included(klass)
			klass.extend(ClassMethods)
			klass.write_inheritable_hash(:hashed_columns, {})
			klass.instance_eval <<-EVAL
				after_initialize :initialize_hashed_columns
			EVAL
		end
		
		private
		
		def hash_before_save
			self.class.hashed_columns.each do |column, options|
				next if hashed?(column)
				@attributes[column.to_s] = nil if read_attribute(column).blank? && !options[:hash_blank_strings]
				perform_hashing_on_column(column, options[:length]) unless read_attribute(column).nil?
			end
		end
		
		def perform_hashing_on_column(column, length)
			@attributes[column.to_s] = HashedString.new(read_attribute(column), :length => length)
		end
		
		def convert_column_to_hashed_string(column)
			@attributes[column.to_s] = HashedString.from_hash(read_attribute(column))
		end
		
		def hashed?(column)
			read_attribute(column.to_s).is_a?(HashedString)
		end
		
		def initialize_hashed_columns
			unless self.new_record?
				self.class.hashed_columns.keys.each do |k|
					convert_column_to_hashed_string(k) unless read_attribute(k).blank?
				end
			end
		end
	
	end
end

ActiveSupport.on_load :active_record do
	class ActiveRecord::Base
		include SaltPepper::ModelExtensions
	end
end