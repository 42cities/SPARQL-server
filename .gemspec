Gem::Specification.new do |gem|
  
    gem.version            = File.read('VERSION').chomp
    gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')
    gem.name               = 'sparql-server'
    gem.rubyforge_project  = 'sparql-server'
    gem.homepage           = 'http://github.com/42cities/sparql-server/'
    gem.summary            = 'Naïve implementation of SPARQL server for RDFMapper'
    gem.description        = 'Naïve implementation of SPARQL server for RDFMapper'
    gem.authors            = ['Alex Serebryakov']
    gem.email              = 'serebryakov@gmail.com'
    gem.platform           = Gem::Platform::RUBY
    gem.files              = %w(README.rdoc UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
    gem.require_paths      = %w(lib)
    gem.has_rdoc           = true
    gem.add_development_dependency 'rspec',       '>= 1.3.0'
    gem.add_runtime_dependency     'rdf',         '>= 0.1.1'
    gem.add_runtime_dependency     'rdf-mapper',  '>= 0.0.1'
    gem.add_runtime_dependency     'rdf-sparql',  '>= 0.0.2'
    gem.post_install_message       = nil
    
end
