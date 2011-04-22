require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe "Model" do

	before(:each) do
		ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
		ActiveRecord::Base.connection.create_table :users do |t|
			t.string :password
			t.string :token
		end
		
		class User; end
		
		@user = Class.new(ActiveRecord::Base) do
			self.table_name = "users"
			@_model_name = ActiveModel::Name.new(User)
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
			@user.encrypt :password, :token
			@user.encrypted_attributes.count.should == 2
			@user.encrypted_attributes.keys.include?(:password).should == true
			@user.encrypted_attributes.keys.include?(:token).should == true
		end
		
		it "should work properly when called multiple times" do
			@user.encrypt :password
			@user.encrypt :token
			@user.encrypted_attributes.count.should == 2
			@user.encrypted_attributes.keys.include?(:password).should == true
			@user.encrypted_attributes.keys.include?(:token).should == true
		end
		
		it "should allow valid parameters" do
			@user.encrypt :password, :length => 100, :skip_blank => false
			@user.encrypted_attributes.count.should == 1
			@user.encrypted_attributes[:password].should == { :length => 100, :skip_blank => false }
		end
		
		it "should apply defaults for unset options" do
			@user.encrypt :password
			@user.encrypted_attributes[:password].should == SaltPepper::DefaultModelOptions
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
		
	end
	
	describe "column encryption" do
	
		it "encrypts column on save" do
			@user.encrypt :password
			@u = @user.new
			@u.password_cleartext.should == ""
			@u.validate_password?.should == true
			@u.password = "secret"
			@u.password_is?("secret").should == true
			@u.validate_password?.should == true
			@u.password_cleartext.should == "secret"
			@u.save!
			@u.validate_password?.should == false
			@u.password_cleartext.should == ""
			@u.password_is?("secret").should == true
			@u.password_is?("oops").should == false
		end
		
		it "does not rehash column if its value was not changed" do
			@user.encrypt :password
			@u = @user.new
			@u.password = "secret"
			@u.save!
			@u.validate_password?.should == false
			@u.save!
			@u.validate_password?.should == false
			@u.password_is?("secret").should == true
			@u.password = @u.password
			@u.validate_password?.should == false
			@u.save!
			@u.password_is?("secret").should == true
		end
		
		it "does not hash column if it is nil or blank" do
			@user.encrypt :password
			@u = @user.new
			@u.validate_password?.should == true
			@u.save!
			@u.password.should be_nil
			@u.validate_password?.should == true
			@u.password = ""
			@u.validate_password?.should == true
			@u.save!
			@u.password.should be_nil
			@u.validate_password?.should == true
			@u.password = "secret"
			@u.validate_password?.should == true
			@u.save!
			@u.validate_password?.should == false
			@u.password = ""
			@u.validate_password?.should == true
			@u.save!
			@u.password_is?("secret").should == true
			@u.validate_password?.should == false
			@u.password = nil
			@u.validate_password?.should == true
			@u.save!
			@u.password_is?("secret").should == true
		end
		
		it "hashes columns with skip_blank: false" do
			@user.encrypt :password, :skip_blank => false
			@u = @user.new
			@u.validate_password?.should == true
			@u.password = nil
			@u.validate_password?.should == true
			@u.save!
			@u.password_is?("").should == true
			@u.validate_password?.should == false
			@u.password = "secret"
			@u.validate_password?.should == true
			@u.save!
			@u.validate_password?.should == false
			@u.password = ""
			@u.validate_password?.should == true
			@u.save!
			@u.password_is?("").should == true
		end
		
		it "works with validations on the column" do
			@user.encrypt :password
			@user.validates :password, :presence => { :if => :new_record? }, :length => { :within => 5..10 }, :if => :validate_password?
			@u = @user.new
			@u.password = ""
			@u.save.should == false
			@u.password = "abc"
			@u.save.should == false
			@u.password = "ooooooooops"
			@u.save.should == false
			@u.password = "valid"
			@u.save.should == true
			@u.save.should == true
			@u.password = ""
			@u.save.should == false
		end
		
		it "works with multiple columns" do
			@user.encrypt :password, :token
			@u = @user.new
			@u.password = "secret"
			@u.save!
			@u.password_is?("secret").should == true
			@u.token.should be_nil
			@u.token = "other"
			@u.save!
			@u.password_is?("secret").should == true
			@u.token_is?("other").should == true
			@u.save!
			@u.password_is?("secret").should == true
			@u.token_is?("other").should == true
		end
	
	end

end