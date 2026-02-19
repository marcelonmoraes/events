require_relative "lib/events/version"

Gem::Specification.new do |spec|
  spec.name        = "events"
  spec.version     = Events::VERSION
  spec.authors     = [ "Marcelo Moraes" ]
  spec.email       = [ "marcelonmoraes@gmail.com" ]
  spec.homepage    = "https://github.com/marcelonmoraes/events"
  spec.summary     = "Rails engine for recording and browsing application events."
  spec.description = "Track user actions, system events, and anything worth logging — from models, controllers, or anywhere in your code. Events are stored in the database and viewable through a mountable monitor dashboard."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/marcelonmoraes/events"
  spec.metadata["changelog_uri"] = "https://github.com/marcelonmoraes/events/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.2"
end
