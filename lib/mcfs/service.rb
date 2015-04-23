
require 'yaml'
require 'logger'
require 'commander'
require 'celluloid'
require 'securerandom'

require_relative 'service/version'
require_relative 'service/namespaces'

require_relative 'service/restv1'

module McFS; module Service
  
  McFS::Service::Log = Logger.new(STDOUT)
  
  # Generate a 1024 bit token to use as secret
  McFS::Service::SECRET_TOKEN = SecureRandom.urlsafe_base64(1024/8)
  
  class Application
    include Commander::Methods
    
    DEFAULT_IP      = '127.0.0.1'
    DEFAULT_PORT    = 8080
    DEFAULT_RUNFILE = ENV['HOME'] + "/.mcfs/mcfs-service.run"
    
    def initialize
      program :name, 'McFS Service'
      program :version, McFS::Service::VERSION
      program :description, 'Multi-cloud file system service'

      command :start do |cmd|
        cmd.syntax = File.basename($0) + ' start [options]'
        cmd.description = 'description for start command'
        
        cmd.option '-l', '--listen IP', String, "Listening IP address (default: #{DEFAULT_IP})"
        cmd.option '-p', '--port PORT', Integer, "Listening port number (default: #{DEFAULT_PORT})"
        
        cmd.option '-R', '--runfile PATH', String, "Path to runtime file to generate (default: #{DEFAULT_RUNFILE})"
  
        cmd.action do |args, options|
          options.default listen:  DEFAULT_IP
          options.default port:    DEFAULT_PORT
          options.default runfile: DEFAULT_RUNFILE
          
          start(args, options)
        end # action
      end # :start

      command :stop do |cmd|
        cmd.syntax = File.basename($0) + ' stop [options]'
        cmd.description = 'description for stop command'
      
        cmd.option '-R', '--runfile PATH', String, "Path to runtime file to read (default: #{DEFAULT_RUNFILE})"

        cmd.action do |args, options|
          options.default runfile: DEFAULT_RUNFILE
          
          stop(args, options)
        end # action
      end # :stop
      
    end # initialize
    
    private

    def start(args, options)
      if File.exists? options.runfile
        Log.error "Runfile #{options.runfile} exits."
        Process.abort
      end
      
      runtime_config = {
        'ip'      => options.listen,
        'port'    => options.port,
        'secret'  => McFS::Service::SECRET_TOKEN,
        'pid'     => Process.pid,
        'service' => File.basename($0),
        'runfile' => options.runfile
      }
      
      update_runtime_config(runtime_config)
      
      McFS::Service::RESTv1.new(runtime_config['ip'], runtime_config['port']).run
    end # start
    
    def stop(args, options)
      pid = YAML.load_file(options.runfile)['pid']
      
      # TODO: need to send QUIT signal instead and make the service
      # capture the signal and terminate gracefully
      #
      # Another method is to send a command to the service via its
      # REST endpoint, wait for some time for the process to quit
      # and then send the KILL signal as a last resort.
      Log.info "Sending INT signal to PID #{pid}"
      
      Process.kill("INT", pid)
    end # stop
    
    def update_runtime_config(runtime_config)
      
      file = runtime_config['runfile']
      
      # Create runtime config file that only the user can
      # read or write
      File.open(file, File::RDWR|File::CREAT, 0600) do |f|
        
        # Get the realpath, in case we change to a different
        # directory
        realpath = Pathname.new(file).realpath
        
        # Ensure file removal on application exit
        at_exit { File.delete realpath }
        
        # Use exclusive lock so that clients never read partial
        # configuration
        f.flock File::LOCK_EX
        
        f.write runtime_config.to_yaml
      end
    end # update_runtime_config
    
  end # class Application
  
end; end
