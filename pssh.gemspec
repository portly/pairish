# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pssh/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Kelly Martin']
  gem.email         = ['kelly@getportly.com']
  gem.summary       = 'Pair Programming made user-friendly with your web browser (and Portly helps).'
  gem.homepage      = 'http://pssh.me'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'pssh'
  gem.require_paths = ['lib']
  gem.version       = Pssh::VERSION

  gem.add_dependency 'json', '~> 1.8.0'
  gem.add_dependency 'rack', '>= 1.5.2', '< 2.3.0'
  gem.add_dependency 'thin', '~> 1.5.0'
  gem.add_dependency 'websocket-rack', '~> 0.4.0'
  gem.add_dependency 'haml', '~> 4.0.0'
  gem.add_dependency 'tilt', '~> 1.4.1'

end

