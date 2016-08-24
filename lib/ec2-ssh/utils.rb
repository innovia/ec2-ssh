module Ec2Ssh::Cli::Utils
  def open_in_terminal
    @all_servers.each do |server|
      `osascript <<-eof
        tell application "iTerm"
          tell current window
            create tab with default profile
            tell the current tab
              activate current session
              tell the last session
                set name to "#{server}"
                write text "ssh -o StrictHostKeyChecking=no ec2-user@#{server}"
              end tell
            end tell
          end tell
        end tell
      eof`
    end
  end
end