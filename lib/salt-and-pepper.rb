require "active_support"
require "active_support/core_ext"
require "active_record"

require "salt_pepper/random"
require "salt_pepper/hashed_string"
require "salt_pepper/model_extensions"

module SaltPepper
	class ArgumentError < ArgumentError; end
end