# encoding: utf-8

Gem::Specification.new do |s|
  s.name          = 'django_signal'
  s.version       = '1.1.0'
  s.authors       = ['Paulo Köch']
  s.email         = ['paulo.koch@gmail.com']
  s.homepage      = 'https://github.com/pkoch/django_signal'
  s.summary       = 'A port of Django\'s Signal.'
  s.description   = 'Because I really wanted something similar to Django\'s Signal in Ruby.'

  s.files         = `git ls-files LICENSE README.md lib`.split("\n")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
end
