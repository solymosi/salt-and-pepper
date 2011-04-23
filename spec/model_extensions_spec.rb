require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe SaltPepper::ModelExtensions do

	before(:each) do
		ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
		ActiveRecord::Base.connection.create_table :users do |t|
			t.string :password
			t.string :token
			t.string :required, :null => false, :default => "something"
		end
		
		class User; end
		
		@user = Class.new(ActiveRecord::Base) do
			self.table_name = "users"
			@_model_name = ActiveModel::Name.new(User)
		end
	end
	
	describe "included?" do
	
		it "should have SaltPepper::ModelExtensions included" do
			@user.included_modules.include?(SaltPepper::ModelExtensions)
		end
		
		it "should add the hash_column class method to the class it's included in" do
			@user.respond_to?("hash_column").should == true
		end

	end
	
	describe "hash_column" do
		
		it "should add a single attribute to the list" do
			@user.hash_column :password
			@user.hashed_columns.count.should == 1
			@user.hashed_columns.keys.include?(:password).should == true
		end
		
		it "should add multiple attributes to the list" do
			@user.hash_column :password, :token
			@user.hashed_columns.count.should == 2
			@user.hashed_columns.keys.include?(:password).should == true
			@user.hashed_columns.keys.include?(:token).should == true
		end
		
		it "should work properly when called multiple times" do
			@user.hash_column :password
			@user.hash_column :token
			@user.hashed_columns.count.should == 2
			@user.hashed_columns.keys.include?(:password).should == true
			@user.hashed_columns.keys.include?(:token).should == true
		end
		
		it "should allow valid parameters" do
			@user.hash_column :password, :length => 100, :skip_blank => false
			@user.hashed_columns.count.should == 1
			@user.hashed_columns[:password].should == { :length => 100, :skip_blank => false }
		end
		
		it "should apply defaults for unset options" do
			@user.hash_column :password
			@user.hashed_columns[:password].should == SaltPepper::ModelExtensions::DefaultHashColumnOptions
		end
		
		it "should not add the same attribute twice" do
			2.times { @user.hash_column :password }
			@user.hashed_columns.count.should == 1
		end
		
		it "should not add an attribute without an existing column to the list" do
			lambda { @user.hash_column :oops }.should raise_error(ArgumentError)
			@user.hashed_columns.should be_empty
		end
		
		it "should not allow invalid parameters" do
			lambda { @user.hash_column :password, :oops => true }.should raise_error(ArgumentError)
		end
		
	end
	
	describe "after_initialize" do
	
		before(:each) do
			@user.hash_column :password
			@u = @user.new
		end
	
		it "should replace the hashed values to a HashedString if not empty and not new_record?" do
			@u.password = "secret"
			@u.save!
			@u = @user.first
			@u.password.is_a?(SaltPepper::HashedString).should == true
			@u.password.respond_to?(:result).should == true
			@u.password.should == "secret"
		end
		
		it "should not replace empty values to a HashedString" do
			@u.password.is_a?(SaltPepper::HashedString).should == false
			@u.save!
			@u = @user.first
			@u.password.is_a?(SaltPepper::HashedString).should == false
		end
	
	end
	
	describe "column hashing on save" do
	
		it "hashes column on save" do
			@user.hash_column :password
			@u = @user.new
			@u.password.should == nil
			@u.validate_password?.should == true
			@u.password = "secret"
			@u.password.class.should == String
			@u.password.should == "secret"
			@u.validate_password?.should == true
			@u.save!
			@u.password.class.should == SaltPepper::HashedString
			@u.password.should == "secret"
			@u.password.should_not == "oops"
			@u.validate_password?.should == false
		end
		
		it "does not rehash column if its value was not changed" do
			@user.hash_column :password
			@u = @user.new
			@u.password = "secret"
			@u.save!
			@u.validate_password?.should == false
			@u.save!
			@u.validate_password?.should == false
			@u.password.should == "secret"
			@u.password = @u.password
			@u.validate_password?.should == false
			@u.save!
			@u.password.should == "secret"
		end
		
		it "does not hash column if it is nil or blank" do
			@user.hash_column :password
			@u = @user.new
			@u.save!
			@u.password.should be_nil
			@u.validate_password?.should == true
			@u.password = ""
			@u.save!
			@u.password.should be_nil
			@u.validate_password?.should == true
			@u.password = "secret"
			@u.save!
			@u.validate_password?.should == false
			@u.password.should == "secret"
			@u.password = ""
			@u.save!
			@u.password.should be_nil
			@u.validate_password?.should == true
			@u.password = nil
			@u.save!
			@u.password.should be_nil
			@u.validate_password?.should == true
		end
		
		it "hashes columns with skip_blank: false" do
			@user.hash_column :password, :skip_blank => false
			@u = @user.new
			@u.password = nil
			@u.save!
			@u.password.should be_nil
			@u.validate_password?.should == true
			@u.password = "secret"
			@u.save!
			@u.validate_password?.should == false
			@u.password = ""
			@u.save!
			@u.password.should == ""
			@u.password.class.should == SaltPepper::HashedString
		end
		
		it "works with validations on the column" do
			@user.hash_column :password
			@user.validates :password, :presence => true, :length => { :within => 5..10 }, :if => :validate_password?
			@u = @user.new
			@u.password = ""
			@u.save.should == false
			@u.password = "abc"
			@u.save.should == false
			@u.password = "ooooooooops"
			@u.save.should == false
			@u.password = "secret"
			@u.save.should == true
			@u.save.should == true
			@u.password = @u.password
			@u.save.should == true
			@u = @user.first
			@u.save.should == true
			@u.password = "abc"
			@u.save.should == false
		end
		
		it "works with multiple columns" do
			@user.hash_column :password, :token
			@u = @user.new
			@u.password = "secret"
			@u.save!
			@u.password.should == "secret"
			@u.token.should be_nil
			@u.token = "other"
			@u.save!
			@u.password.should == "secret"
			@u.token.should == "other"
			@u.save!
			@u.password.should == "secret"
			@u.token.should == "other"
		end
		
		it "remains in a consistent state if saving fails" do
			@user.hash_column :password
			@u = @user.new
			@u.required = nil
			@u.password = "secret"
			@u.save! rescue nil
			@u.password.should == "secret"
			@u.validate_password?.should == false
			@u.required = "something"
			@u.save!
			@u.password.should == "secret"
			@u.validate_password?.should == false
		end
		
		it "works with finds" do
			@user.hash_column :password
			@u = @user.new
			@u.password = "secret"
			@u.save
			@v = @user.first
			@v.validate_password?.should == false
			@u.password.should == "secret"
			@v.password = nil
			@v.save
			@w = @user.first
			@w.validate_password?.should == true
			@w.password.should be_nil
		end
	
	end

end