class AppGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  puts "Testing..."
  def setup_git
    git :init
    git :add => "."
    git :commit => "-a -m 'Initial commit'"
  end
end
