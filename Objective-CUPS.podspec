Pod::Spec.new do |s|
  s.name         	= "Objective-CUPS"
  s.version      	= "0.1.0"
  s.summary      	= "Objective-C framework for interacting with the CUPS system."

  s.description  	= <<-DESC
                    Objective-C framework for interacting with the CUPS system. The Printer object conforms to
                    NSSecureCoding to be used with a NSXPC Service and priviledged helper tool so non-admin
                    users can manage printers themselves.
                    DESC

  s.homepage     	= "https://github.com/eahrold/Objective-CUPS"
  s.license      	= { :type => 'MIT', :file => 'LICENSE' }
  s.authors      	= "Eldon Ahrold" 
  
  s.source        = { :git => "https://github.com/eahrold/Objective-CUPS.git", :tag => "0.1" }
  s.source_files  = 'Objective-CUPS', 'Objective-CUPS/**/*.{h,m}'
  
  s.osx.deployment_target = "10.8"
  s.requires_arc          = true
end
