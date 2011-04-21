require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe SaltPepper do

	describe "random_number" do
	
		it "(most likely) works when only a max value is specified" do
			100.times { (0..1).include?(SaltPepper.random_number(2)).should == true }
		end
		
		it "(most likely) works when a range is specified" do
			100.times { (9..10).include?(SaltPepper.random_number(9..10)).should == true }
		end
		
		it "is (most likely) random" do
			values = []
			100.times { values << SaltPepper.random_number(9..10) }
			values.uniq.count.should == 2
		end
	
	end
	
	describe "code" do
	
		it "works without any parameters" do
			SaltPepper::code.length.should == 8
			SaltPepper::code.should =~ /\A[A-Z0-9]+\z/
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

end