require "#{Dir.pwd}/spec/spec_helper"

describe 'Visiting home page' do
	it "Should have homepage content" do
		visit '/'
		page.should have_content('asdffh')
	end
end

#
#describe "visiting services page" do
#	it "should have required content" do
#		visit '/about'
#		page.should have_content('Hassle-free Real Estate')
#	end
#end

#describe "Searching for property" do
#	before do
#		visit '/'
#		first(:button, "Search").click
#	end
#	it "should load the search page" do
#		page.should have_content("Locations")
#	end
#end

#describe "Visit Sell/Lease" do
#	before { visit '/sell-lease' }
#	it "should have the required content" do
#		page.should have_title("GoaPropertyCo | Sell or Lease Your Property")
#	end
#end

#describe "Searching for Sale Property in North Goa" do
#	before {visit '/search?search%5Bcategory%5D=1&search%5Bstate%5D=1&search%5Bregion_id%5D=1&submit=' }
#	it "Should have a property for sale from Mapusa" do
#		page.should have_content("Blank")
#	end
#end

#feature "Visiting property page" do
#	scenario "with authorisation" do
#		page.driver.browser.authorize 'hashcookies', 'iomega'
#		visit '/property/new' 
#		expect(page).to have_content('Create New Property')
#	end
#	scenario "with poor authorization" do
#		page.driver.browser.authorize 'brashhookies', 'boozeo'
#		visit '/property/new'
#		expect(page).to have_content('Authorization Required')
#		expect(page).to_not have_content('Create New Property')
#	end
#end
#
#feature "creating a property" do
#	scenario "creating a new propertyd" do
#		page.driver.browser.authorize 'hashcookies', 'iomega'
#		visit '/property/new' 
#		click_button "Create New Property"
#		expect(page).to have_content('Interested?')
#	end
#end