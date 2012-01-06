require 'buildr4osgi'

desc "An example Buildr4osgi project which builds a dummy p2site"

define('container') do
  project.group = "grp"
  project.version = '1.0.0'
  
  define("bar", :version => "1.0.0") do
    compile { FileUtils.makedirs _('target/root/resources') }
    package(:bundle)
    package(:sources)
  end
 
  define("foo", :version => "1.0.0") do
    f = package(:feature)
    f.plugins << project("container:bar")
    f.label = "My feature using a p2site"
    f.provider = "Acme Inc"
    f.description = "The best feature ever"
    f.changesURL = "http://example.com/changes"
    f.license = "The license is too long to explain"
    f.licenseURL = "http://example.com/license"
    f.branding_plugin = "com.musal.ui"
    f.update_sites << {:url => "http://example.com/update", :name => "My dummy p2site site"}
    f.discovery_sites = [{:url => "http://example.com/update2", :name => "My dummy p2site site2"}, 
      {:url => "http://example.com/upup", :name => "My update site in case"}]
  end
  
  category = Buildr4OSGi::Category.new
  category.name = "category.id"
  category.label = "Some Label"
  category.description = "The category is described here"
  category.features<< project('foo')
  package(:site).categories << category
  package(:p2_from_site)
end
