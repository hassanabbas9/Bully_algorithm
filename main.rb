#!/usr/bin/env ruby
# Author Name: Hassan Abbas

require './bully_process.rb'

@bully_process = Bully_Process.new(ARGV[0] ,ARGV[1])
@bully_process.read_from_file()
@bully_process.set_initial_cordinator
