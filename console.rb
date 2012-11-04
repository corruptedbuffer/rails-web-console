#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"

require "vmc"
require "cli"
require "uuidtools"

class Console < VMC::Cli::Command::Base

  include VMC::Cli::TunnelHelper
  include VMC::Cli::ConsoleHelper

  class << self
    attr_accessor :telnet_clients
  end

  def self.sessions
    self.telnet_clients.keys
  end

  def self.add_telnet_client(telnet_client)
    self.telnet_clients = {} if self.telnet_clients.nil?
    guid = UUIDTools::UUID.random_create.to_s
    self.telnet_clients[guid] = telnet_client
    guid
  end

  def self.talk(guid, msg)
    telnet_client = self.telnet_clients[guid]
    results = telnet_client.cmd(msg)
    results.split("\n")
  end

  def self.purge_sessions

    self.telnet_clients.each do |k, c|
      c.cmd("String"=>"exit","Timeout"=>1) rescue TimeoutError
      c.close
    end
    
    self.telnet_clients = {}
  end

  def self.close_session(guid)
    telnet_client = self.telnet_clients[guid]

    telnet_client.cmd("String"=>"exit","Timeout"=>1) rescue TimeoutError
    telnet_client.close

    self.telnet_clients.delete telnet_client
  end

  def connect(target, username, password)
    @client = VMC::Client.new target
    @client.login username, password
  end

  def console(appname)

    err "Caldecott is not installed." unless defined? Caldecott

    #Make sure there is a console we can connect to first
    conn_info = console_connection_info appname

    port = pick_tunnel_port(@options[:port] || 20000)

    raise VMC::Client::AuthError unless client.logged_in?

    if not tunnel_pushed?
      display "Deploying tunnel application '#{tunnel_appname}'."
      auth = UUIDTools::UUID.random_create.to_s
      push_caldecott(auth)
      start_caldecott
    else
      auth = tunnel_auth
    end

    if not tunnel_healthy?(auth)
      display "Redeploying tunnel application '#{tunnel_appname}'."
      # We don't expect caldecott not to be running, so take the
      # most aggressive restart method.. delete/re-push
      client.delete_app(tunnel_appname)
      invalidate_tunnel_app_info
      push_caldecott(auth)
      start_caldecott
    end

    start_tunnel(port, conn_info, auth)
    wait_for_tunnel_start(port)

    start_local_console(port, appname)
  end

  def start_local_console(port, appname)
    auth_info = console_credentials(appname)
    prompt = console_login(auth_info, port)

    clear(80)

    initialize_readline

    # store the telnet client for future requests 
    guid = Console.add_telnet_client @telnet_client
    [guid, prompt]

  end

  def run_console(prompt)

    puts @telnet_client.inspect
    prev = trap("INT")  { |x| exit_console; prev.call(x); exit }
    prev = trap("TERM") { |x| exit_console; prev.call(x); exit }
    loop do
      cmd = readline_with_history(prompt)
      if(cmd == nil)
        exit_console
        break
      end
      prompt = send_console_command_display_results(cmd, prompt)
    end
  end

end