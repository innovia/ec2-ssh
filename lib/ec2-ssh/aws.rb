module Ec2Ssh::Cli::Aws
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
end