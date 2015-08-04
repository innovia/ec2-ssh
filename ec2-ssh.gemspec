$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../lib/ec2-ssh", __FILE__)

require File.expand_path('../lib/ec2-ssh', __FILE__)

Gem::Specification.new do |s|
  s.name        = "ec2-ssh"
  s.version     = Ec2Ssh::VERSION
  s.authors     = ["Ami Mahloof"]
  s.email       = "ami.mahloof@gmail.com"
  s.homepage    = "https://github.com/innovia/ec2-ssh"
  s.summary     = "run commmands on multiple servers by tag or by autoscale group"
  s.description = "EC2 SSH Utility"
  s.required_rubygems_version = ">= 1.3.6"
  s.files = `git ls-files`.split($\).reject{|n| n =~ %r[png|gif\z]}.reject{|n| n =~ %r[^(test|spec|features)/]}
  s.add_runtime_dependency 'thor', '~> 0.19', '>= 0.19.1'
  s.add_runtime_dependency 'aws-sdk', '~> 2.0.45', '>= 2.0.45'
  s.add_runtime_dependency 'sshkit', '~> 1.7.1', '>= 1.7.1'
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.license = 'MIT'
end
