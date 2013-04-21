module Oxidized
  require 'net/telnet'
  require 'oxidized/input/cli'
  class Telnet < Input
    include CLI 
    attr_reader :telnet

    def connect node
      @node    = node
      @timeout = CFG.timeout
      @node.model.cfg['telnet'].each { |cb| instance_exec &cb }
      begin
        @telnet  = Net::Telnet.new 'Host' => @node.ip, 'Waittime' => @timeout
        expect username
        @telnet.puts @node.auth[:username]
        expect password
        @telnet.puts @node.auth[:password]
        expect @node.prompt
      rescue  Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout
        return false
      end
    end

    def cmd cmd, expect=@node.prompt
      Log.debug "Telnet: #{cmd} @#{@node.name}"
      args = { 'String' => cmd }
      args.merge!({ 'Match' => expect, 'Timeout' => @timeout }) if expect
      @telnet.cmd args
    end

    private

    def expect re
      @telnet.waitfor 'Match' => re, 'Timeout' => @timeout
    end

    def disconnect
      @pre_logout.each { |command| cmd(command, nil) }
      @telnet.close
    end

    def username re=/^(Username|login)/
      @username or @username = re
    end

    def password re=/^Password/
      @password or @password = re
    end

  end
end