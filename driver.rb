#!/usr/bin/env ruby
# Author Name: Hassan Abbas

text = File.open('configuration_file').read
text.each_line do |line|
  line_num = line.split(" ").first
  host_name = line.split(" ")[1]
  job = fork do
    system "ssh #{host_name} ruby main.rb configuration_file #{line_num}"
  end
  Process.detach(job)
end
