require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe SaltPepper do

	describe "random_number" do
	
		it "(most likely) works when only a max value is specified" do
			100.times { (0..1).include?(SaltPepper.random_number(2)).should == true }
		end
		
		it "(most likely) works when a range is specified" do
			100.times { (9..10).include?(SaltPepper.random_number(9..10)).should == true }
		end
	
	end
	
	describe "code" do
	
		it "works without any parameters" do
			SaltPepper::code.length.should == 8
		end
		
		it "returns uppercase alphanumeric characters" do
			SaltPepper::code(1000).should =~ /\A[A-Z0-9]+\z/
		end
		
		it "works with a size parameter" do
			SaltPepper::code(10).length.should == 10
		end
		
		it "works with size and chars parameters" do
			SaltPepper::code(100, 0..1).chars.to_a.uniq.sort.should == ["0", "1"].sort
		end
		
		it "(most likely) works when a range is specified" do
			100.times { (9..10).include?(SaltPepper.random_number(9..10)).should == true }
		end
	
	end
	
	describe "numeric_code" do
		
		it "returns numbers only" do
			SaltPepper::numeric_code(100).should =~ /\A[0-9]+\z/
		end
	
	end
	
	describe "alpha_code" do
		
		it "returns uppercase letters only" do
			SaltPepper::alpha_code(100).should =~ /\A[A-Z]+\z/
		end
	
	end
	
	describe "token" do
		
		it "works without parameters" do
			SaltPepper::token.length.should == 32
		end
		
		it "works with a size parameter" do
			SaltPepper::token(100).length.should == 100
		end
		
		it "returns hex characters" do
			SaltPepper::token(1000).should =~ /\A[a-f0-9]*\z/
		end
	
	end
	
	describe "encrypt" do
		
		it "works without options parameter" do
			hash = SaltPepper::encrypt("secret")
			hash.length.should == 128
			hash.should =~ /\A[a-f0-9]*\z/
			Digest::SHA256.hexdigest("secret:#{hash[64...128]}").should == hash[0...64]
		end
		
		it "works with custom options" do
			hash = SaltPepper::encrypt("secret", :algorithm => :md5, :salt_size => 32)
			hash.length.should == 64
			hash.should =~ /\A[a-f0-9]*\z/
			Digest::MD5.hexdigest("secret:#{hash[32...64]}").should == hash[0...32]
		end
		
		it "uses default values for missing options" do
			hash = SaltPepper::encrypt("secret", :salt_size => 128)
			hash.length.should == 192
		end
	
	end
	
	describe "verify" do
		
		it "works without options parameter" do
			hash = SaltPepper::encrypt("secret")
			SaltPepper::verify("secret", hash).should == true
			SaltPepper::verify("oops", hash).should == false
		end
		
		it "works with custom options" do
			hash = SaltPepper::encrypt("secret", :algorithm => :md5, :salt_size => 100)
			SaltPepper::verify("secret", hash, :algorithm => :md5, :salt_size => 100).should == true
			SaltPepper::verify("oops", hash, :algorithm => :md5, :salt_size => 100).should == false
		end
		
		it "uses default values for missing options" do
			hash = SaltPepper::encrypt("secret", :algorithm => :md5)
			SaltPepper::verify("secret", hash, :algorithm => :md5).should == true
			SaltPepper::verify("oops", hash, :algorithm => :md5).should == false
		end
	
	end

end