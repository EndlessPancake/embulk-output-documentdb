# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "embulk-output-documentdb"
  spec.version       =  File.read("VERSION").strip
  spec.authors       = ["Yoichi Kawasaki"]
  spec.email         = ["yoichi.kawasaki@outlook.com"]
  spec.summary       = "Azure DocumentDB output plugin for Embulk"
  spec.description   = "Dumps records to Azure DocumentDB"
  spec.licenses      = ["MIT"]
  spec.homepage      = "https://github.com/yoichika/embulk-output-documentdb"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client"
  spec.add_development_dependency 'embulk', ['>= 0.8.13']
  spec.add_development_dependency 'bundler', ['>= 1.10.6']
  spec.add_development_dependency 'rake', ['>= 10.0']
end
