#!/usr/bin/env ruby
# Author Name: Hassan Abbas
require "socket"

class Bully_Process

  def initialize(file_name, id)
    @line_num = id
    @process_ids = []
    @host_names = []
    @port_nos = []
    @ln_no = 1
    @process_id = 0
    @process_host_name = ""
    @process_port_no = ""
    @cordinator_id = 0
    @file_name = file_name
    @intial_cordinator_id = 0
    @current_cordinator_id = nil
    @msg = ""
  end

  def set_initial_cordinator
    if (@process_ids.sort.last == @process_id)
      @cordinator_id = @process_id
      index = @process_ids.index(@process_id)
      p_no = @port_nos[index]
      rec_messages(10, p_no, @cordinator_id)
    elsif @intial_cordinator_id != 0

      t1 = Thread.new {
        dts = TCPServer.new('0.0.0.0', @process_port_no)
        loop do
          Thread.start(dts.accept) do |s|
          @msg = s.recv( 1000 )
          s.close
          end
      end
      }

      while @current_cordinator_id != @process_id do
        time1 = Time.now
        time2 = Time.now + 15
        while (Time.now) < time2 do
          sleep 5
          ping_cordinator("alive?", @intial_cordinator_id) if @intial_cordinator_id != 0
          ping_cordinator("alive?", @current_cordinator_id) unless @current_cordinator_id.nil?
          if (@msg == "Yes #{@intial_cordinator_id}")
          elsif (@msg.include? "NC")
            @current_cordinator_id = @msg.split(" ").last
            @remaining_processes.delete(@current_cordinator_id)
            @remaining_processes.delete(@intial_cordinator_id) if @intial_cordinator_id != 0
            @intial_cordinator_id = 0
          end
        end
        send_election_messages()
        set_new_cordinator()
      end
      if(@current_cordinator_id == @process_id)
        index = @process_ids.index(@process_id)
        p_no = @port_nos[index]
        rec_messages(10, p_no, @process_id)
      end
      t1.exit
      exit
    end
  end

  def set_new_cordinator()
    electables = []
    if ((@msg.include? "Election") || (@msg.include? "Yes") || ((@remaining_processes.length == 1)))
      @remaining_processes.sort.each do |id|
        if(id >= @process_id && id != @intial_cordinator_id && id != @current_cordinator_id)
          electables << id
        end
      end
      unless (electables.empty?)
        if (electables.last == @process_id)
          print "c #{@process_id}\n"
          @current_cordinator_id = @process_id
          @remaining_processes.delete(@process_id)
          @remaining_processes.delete(@intial_cordinator_id) if @intial_cordinator_id != 0
          @intial_cordinator_id = 0
          @process_ids.each do |id|
            index = @process_ids.index(id)
            hst_name = @host_names[index]
            p_no = @port_nos[index]
            begin
            streamSock = TCPSocket.new( hst_name, p_no )
            streamSock.write( "NC #{@current_cordinator_id}" )
            streamSock.close
            rescue
            end
          end
        end
      end
    end
  end

  def read_from_file()
    text = File.open(@file_name).read
    text.each_line do |line|
      id = line.split(" ").first
      host_name = line.split(" ")[1]
      port_no = line.split(" ").last
      @process_ids << id
      @host_names << host_name
      @port_nos << port_no
      if (id == @line_num)
        @process_id = id
        @process_host_name = host_name
        @process_port_no = port_no
      end
    end
    @intial_cordinator_id = @process_ids.sort.last
    @remaining_processes = Array.new(@process_ids)
  end

  def send_election_messages()
    electable_ids = []
    @process_ids.sort.each do |id|
      if (id > @process_id)
        electable_ids << id
      end
    end
    unless electable_ids.empty?
      print "e ["
      electable_ids.each do |id|
        print "#{id} "
      end
      print "]\n"
      electable_ids.each do |id|
        index = @process_ids.index(id)
        hst_name = @host_names[index]
        p_no = @port_nos[index]
        begin
          streamSock = TCPSocket.new( hst_name, p_no )
          streamSock.write( "Election #{@process_id}" )
          streamSock.close
        rescue
        end
      end
    end
  end

  def ping_cordinator(msg, cordinator_id)
    index = @process_ids.index(cordinator_id)
    hst_name = @host_names[index]
    p_no = @port_nos[index]
    begin
      streamSock = TCPSocket.new( hst_name, p_no )
      streamSock.write( "alive? #{@process_id}" )
      streamSock.close
    rescue
    end
  end

  def send_message(msg, cordinator_id)
    if (msg.include? "alive?")
      id = msg.split(" ").last
      index = @process_ids.index(id)
      hst_name = @host_names[index]
      p_no = @port_nos[index]
      begin
        streamSock = TCPSocket.new( hst_name, p_no )
        streamSock.write( "Yes #{cordinator_id}" )
        streamSock.close
      rescue
      end
    end
  end

  def rec_messages(time, port_no, cordinator_id)
    begin
      t2 = Thread.new {
        dts = TCPServer.new('0.0.0.0', port_no)
        loop do
          Thread.start(dts.accept) do |s|
          @msg = s.recv( 1000 )
          s.close
          end
      end
      }
    rescue
    end

    time2 = Time.now + time
    while (Time.now) < time2 do
      if (@msg.include? "alive?")
        id = @msg.split(" ").last
        send_message(@msg, cordinator_id)
      end
    end
    print "t #{@process_id}\n"
    t2.exit
    exit if @intial_cordinator_id !=0 || !(@current_cordinator_id.nil?)
  end

end
