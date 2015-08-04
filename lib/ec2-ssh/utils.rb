module Ec2Ssh::Cli::Utils
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