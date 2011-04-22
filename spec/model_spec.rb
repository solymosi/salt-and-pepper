require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe "User model" do

	before(:each) do
		ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
		ActiveRecord::Base.connection.create_table :users do |t|
			t.string :password, :null => false
			t.string :some_token
		end
		
		@user = Class.new(ActiveRecord::Base) do
			self.table_name = "users"
			
			encrypt :password
			
			#validates :password, :length => { :maximum => 50, :if => :password_changed? }
		end
	end

	it "should have the salt and pepper module included" do
		@user.included_modules.include?(SaltPepper::ModelExtensions)
	end
	
	it "should have an encrypt class method" do
		@user.respond_to?("encrypt").should == true
	end
	
	describe "encrypt method" do
		
		it "should add a single attribute to the list" do
			@user.encrypt :password
			@user.encrypted_attributes.count.should == 1
			@user.encrypted_attributes.keys.include?(:password).should == true
		end
		
		it "should add multiple attributes to the list" do
			@user.encrypt :password, :some_token
			@user.encrypted_attributes.count.should == 2
			@user.encrypted_attributes.keys.include?(:password).should == true
			@user.encrypted_attributes.keys.include?(:some_token).should == true
		end
		
		it "should work properly when called multiple times" do
			@user.encrypt :password
			@user.encrypt :some_token
			@user.encrypted_attributes.count.should == 2
			@user.encrypted_attributes.keys.include?(:password).should == true
			@user.encrypted_attributes.keys.include?(:some_token).should == true
		end
		
		it "should allow valid parameters" do
			@user.encrypt :password, :length => 100
			@user.encrypted_attributes.count.should == 1
			@user.encrypted_attributes[:password].should == { :length => 100 }
		end
		
		it "should apply defaults for unset options" do
			@user.encrypt :password
			@user.encrypted_attributes[:password][:length].should == SaltPepper::DefaultOptions[:length]
		end
		
		it "should not add the same attribute twice" do
			2.times { @user.encrypt :password }
			@user.encrypted_attributes.count.should == 1
		end
		
		it "should not add an attribute without an existing column to the list" do
			lambda { @user.encrypt :oops }.should raise_error(ArgumentError)
			@user.encrypted_attributes.should be_empty
		end
		
		it "should not allow invalid parameters" do
			lambda { @user.encrypt :password, :oops => true }.should raise_error(ArgumentError)
		end
		
		it "should not allow invalid algorithm" do
			lambda { @user.encrypt :password, :algorithm => :oops }.should raise_error(ArgumentError)
		end
		
		it "should not allow invalid salt size" do
			lambda { @user.encrypt :password, :salt_size => 0 }.should raise_error(ArgumentError)
			lambda { @user.encrypt :password, :salt_size => -10 }.should raise_error(ArgumentError)
			lambda { @user.encrypt :password, :salt_size => 1000 }.should raise_error(ArgumentError)
			lambda { @user.encrypt :password, :salt_size => false }.should raise_error(ArgumentError)
			lambda { @user.encrypt :password, :salt_size => "oops" }.should raise_error(ArgumentError)
		end
		
	end
	
	#describe "column encryption" do
	
	#	it "should add a before_save hook" do
	#		@user
	#	end
	
	#end

end