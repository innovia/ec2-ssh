require 'sshkit'
require 'sshkit/dsl'
include SSHKit::DSL

module Ec2Ssh::Cli::Ssh
  def set_ssh(user)
    ENV['SSHKIT_COLOR'] = 'TRUE'
    SSHKit.config.output_verbosity = Logger::DEBUG
    SSHKit::Backend::Netssh.configure { |ssh|
      ssh.ssh_options = {
        :user => user,
        :paranoid => false,
        :forward_agent => true,
        :user_known_hosts_file => '/dev/null'
      }
    }
  end

  def ssh_to(user, dsl_options, cmd)
    say "Running #{cmd} via ssh in #{dsl_options}", color = :cyan
    on(@all_servers, in: dsl_options[:in]) { |host| execute cmd }
  end
end