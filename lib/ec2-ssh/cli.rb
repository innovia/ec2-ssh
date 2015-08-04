#!/usr/bin/env ruby
# encoding: utf-8
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib]))

require 'aws-sdk'
require 'thor'
require 'pp'
require 'sshkit'
require 'sshkit/dsl'

class Ec2Ssh::Cli  < Thor
  include Thor::Actions
  default_task :connect

  desc "connect", "Connect to autoscale instance (random instance), Pass --cmd='whatever' to run a cmd on the server"
  method_option :cmd,                              :desc => 'commmand to run on remote servers', :required => true
  method_option :profile,                          :desc => 'aws cli profile', :default => 'default'
  method_option :region,                           :desc => "region", :default => 'us-east-1'
  method_option :user,            :aliases => 'u', :desc => 'run as user', :default => 'ec2-user'
  method_option :parallel,        :aliases => 'p', :desc => 'run in parallel'
  method_option :sequence,        :aliases => 's', :desc => 'run in sequence'
  method_option :groups,          :aliases => 'g', :desc => 'run in groups'
  method_option :groups_limit,    :aliases => 'l', :desc => 'limit', :type => :numeric
  method_option :wait,            :aliases => 'w', :desc => 'wait',  :type => :numeric
  method_option :as,                               :desc => 'get autoscale groups'
  method_option :tag_key,                          :desc => 'tag key to filter instances by', :default => 'Name'
  method_option :tag_value,                        :desc => 'tag value to filter instances by'
  method_option :terminal,        :aliases => 't', :desc => 'open terminal tabs for all servers'
  def connect
    set_ssh(options[:user])
    aws_init(options[:profile], options[:region])
      
    if options[:as]
      get_auto_scale_groups
    elsif options[:tag_value]
      get_instances(options[:tag_key].chomp, options[:tag_value].chomp)
    end
    
    if options[:terminal]
      open_in_terminal
    else

      if options[:parallel] && options[:sequence]
        say "You can't run both in sequence and in parallel at the same time"
        exit 1
      end

      mode = :parallel if options[:parallel]
      mode = :groups   if options[:groups]
      mode = :sequence if options[:sequence]

      mode = :parallel if mode.nil? 
      dsl_options = {}
      dsl_options[:in] = mode
      dsl_options[:wait]  = options[:wait] if options[:wait]
      dsl_options[:limit] = options[:groups_limit] if options[:groups_limit]
      
      puts "dsl opts: #{dsl_options}"
      ssh_to(options[:user], dsl_options, options[:cmd])
    end
  end

  map ["-v", "--version"] => :version
  desc "version", "version"
  def version
    say Ec2Ssh::ABOUT, color = :green
  end  

private
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

  def aws_init(profile, region)
    ENV['AWS_PROFILE'] = profile
    Aws.config.update({region: region})

    @region = region
    @as = Aws::AutoScaling::Client.new()
    @ec2 = Aws::EC2::Client.new()

    say "Currently running user is: #{Aws::IAM::CurrentUser.new.arn}"
  end

  def get_auto_scale_groups
    say "Fetching AutoScale Groups - please wait..."
      @as_groups = @as.describe_auto_scaling_groups.auto_scaling_groups

      as_group_names = @as_groups.inject([]) {|acc, asg| acc << asg.auto_scaling_group_name; acc }

      as_selection = {}
      as_group_names.each_with_index.inject(as_selection) {|acc, pair|
        element, index = pair
        as_selection[index] = element
        acc
      } 
      
      say "AutoScale Group in #{options[:region]}:\n"
      as_selection.each {|k,v| say "#{k}: #{v}"}

      selected_as = ask("Which server group do you want to ssh to?", color = :yellow)
      
      get_instances('aws:autoscaling:groupName', as_selection[selected_as.to_i])
  end

  def get_instances(tag_key, tag_value)
    @all_servers = []

    response = @ec2.describe_instances({
      filters: [
      {
        name: 'instance-state-code',
        values: ['16']

      },{
        name: 'tag-key',
        values: ["#{tag_key}"]
      },{
        name: 'tag-value',
        values: ["#{tag_value}"]
      }
    ]
    })

    if !response.reservations.empty?
      response.reservations.each {|r| r.instances.inject(@all_servers){|acc, k| acc << k.public_ip_address; acc}}
    else
      say "could not find any instances with the tag #{tag_key}: #{tag_value} on #{@region}"
    end

    say "All servers: #{@all_servers.size}"
  end

  def ssh_to(user, dsl_options, cmd)
    say "Running #{cmd} via ssh in #{dsl_options}", color = :cyan
    on @all_servers, dsl_options  do |host|
        execute cmd
    end
  end

  def open_in_terminal
    @all_servers.each do |server|
      `osascript <<-eof
         tell application "iTerm"
          make new terminal
          tell the current terminal
            activate current session
            launch session "Default Session"
            tell the last session
              set name to "#{server}"
              write text "ssh ec2-user@#{server}"
            end tell
          end tell
         end tell
      eof`
    end
  end
end