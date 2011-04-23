require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe SaltPepper::HashedString do

	before(:each) do
		@hash = SaltPepper::HashedString.new("secret")
	end

	describe "initialize" do
		
		it "raises error invalid parameters" do
			lambda { SaltPepper::HashedString.new(nil) }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.new(3) }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.new([]) }.should raise_error(SaltPepper::ArgumentError)
		end
		
		it "accepts valid parameters" do
			lambda { SaltPepper::HashedString.new("") }.should_not raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.new("secret") }.should_not raise_error(SaltPepper::ArgumentError)
		end
		
		it "generates a valid salt with default length" do
			@hash.salt.length.should == SaltPepper::HashedString::DefaultOptions[:length] - 64
		end
		
		it "generates a valid salt with custom length" do
			SaltPepper::HashedString.new("secret", :length => 192).salt.length.should == 128
		end
		
		it "raises error for invalid options" do
			lambda { SaltPepper::HashedString.new("secret", :length => 95) }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.new("secret", :length => 197) }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.new("secret", :length => true) }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.new("secret", :length => "oops") }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.new("secret", :oops => true) }.should raise_error(SaltPepper::ArgumentError)
		end
		
		it "hashes the input string" do
			@hash.hsh.should_not be_blank
		end
	
	end
	
	describe "hsh" do
		it "returns the hash" do
			@hash.hsh.should == @hash.result[0...64]
		end
	end
	
	describe "salt" do
		it "returns the salt" do
			@hash.salt.should == @hash.result[64...128]
		end
	end
	
	describe "to_s" do
		it "returns empty string" do
			@hash.to_s.should == ""
		end
	end
	
	describe "to_yaml" do
		it "returns the result" do
			@hash.to_yaml.should == @hash.result
		end
	end
	
	describe "inspect" do
		it "returns result.inspect" do
			@hash.inspect.should == @hash.result.inspect
		end
	end
	
	describe "set_attributes" do
		it "sets attributes correctly" do
			@hash.set_attributes("hehe", "haha")
			@hash.hsh.should == "hehe"
			@hash.salt.should == "haha"
		end
	end
	
	describe "==" do
	
		it "returns true if String is given and verification succeeds" do
			@hash.should == "secret"
		end
		
		it "returns false if String is given and verification fails" do
			@hash.should_not == "oops"
		end
		
		it "returns true if another HashedString is given and they match" do
			h = SaltPepper::HashedString.from_hash(@hash)
			@hash.should == h
		end
		
		it "returns false if another HashedString is given but they don't match" do
			h = SaltPepper::HashedString.new("oops")
			@hash.should_not == h
		end
		
		it "returns false if something other than a String or HashedString is given" do
			@hash.should_not == 10
			@hash.should_not == []
			@hash.should_not == {}
		end
	
	end
	
	describe "from_hash" do
	
		before(:each) do
			@f = SaltPepper::HashedString.from_hash(@hash)
		end
	
		it "raises error for invalid parameters" do
			lambda { SaltPepper::HashedString.from_hash(nil) }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.from_hash(10) }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.from_hash("o" * 95) }.should raise_error(SaltPepper::ArgumentError)
			lambda { SaltPepper::HashedString.from_hash("o" * 197) }.should raise_error(SaltPepper::ArgumentError)
		end
		
		it "separates the hash and the salt correctly" do
			@f.hsh.should == @hash.hsh
			@f.salt.should == @hash.salt
			@f.should == @hash
			@f.should == "secret"
		end
	
	end
	
	describe "eql?" do
		it "works correctly" do
			SaltPepper::HashedString.from_hash(@hash.result).eql?(@hash).should == true
		end
	end
	
	describe "String extension" do
		it "works correctly" do
			"secret".should == @hash
		end
	end
	
	describe "validation help messages" do
		it "work correctly" do
			lambda { @hash.blank? }
		end
	end

end