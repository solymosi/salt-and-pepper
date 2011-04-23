require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe SaltPepper::Random do

	describe "number" do
	
		it "(most likely) works when only a max value is specified" do
			100.times { (0..1).include?(SaltPepper::Random.number(2)).should == true }
		end
		
		it "(most likely) works when a range is specified" do
			100.times { (9..10).include?(SaltPepper::Random.number(9..10)).should == true }
		end
	
	end
	
	describe "code" do
	
		it "works without any parameters" do
			SaltPepper::Random.code.length.should == 8
		end
		
		it "returns uppercase alphanumeric characters" do
			SaltPepper::Random.code(1000).should =~ /\A[A-Z0-9]+\z/
		end
		
		it "works with a size parameter" do
			SaltPepper::Random.code(10).length.should == 10
		end
		
		it "works with size and chars parameters" do
			SaltPepper::Random.code(100, 0..1).chars.to_a.uniq.sort.should == ["0", "1"].sort
		end
	
	end
	
	describe "numeric_code" do
		
		it "returns numbers only" do
			SaltPepper::Random.numeric_code(100).should =~ /\A[0-9]+\z/
		end
	
	end
	
	describe "alpha_code" do
		
		it "returns uppercase letters only" do
			SaltPepper::Random.alpha_code(100).should =~ /\A[A-Z]+\z/
		end
	
	end
	
	describe "token" do
		
		it "works without parameters" do
			SaltPepper::Random.token.length.should == 32
		end
		
		it "works with a size parameter" do
			SaltPepper::Random.token(100).length.should == 100
		end
		
		it "returns hex characters" do
			SaltPepper::Random.token(1000).should =~ /\A[a-f0-9]*\z/
		end
	
	end
	
	describe "methods" do
		it "are available on SaltPepper itself" do
			SaltPepper.respond_to?(:number).should == true
			SaltPepper.respond_to?(:code).should == true
			SaltPepper.respond_to?(:alpha_code).should == true
			SaltPepper.respond_to?(:numeric_code).should == true
			SaltPepper.respond_to?(:token).should == true
		end
	end
	
end