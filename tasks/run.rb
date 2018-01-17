#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'open3'
require 'tmpdir'

def exec(command)
  Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
    while line = stdout_err.gets
#      puts line
    end

    output = stdout_err
    exit_code = wait_thr.value
  end

  puts "output:#{output}"
  puts "exit  :#{exit_code}"
  
  File.open("#{Dir.tmpdir()}#{File::SEPARATOR}taskulator.log", 'a') { |file| file.write("#{output}") }
  
  { _output: output,
    exit_code: exit_code
  }
end

def install_module(mod)
  exec("puppet module install #{mod}")
  puts "#{mod} installed"
end

def uninstall_module(mod)
  exec("puppet module uninstall #{mod}")
end

def puppet_apply(code)
  File.open("#{Dir.tmpdir()}#{File::SEPARATOR}taskulator.pp", 'w') { |file| file.write("#{code}") }  
  exec("puppet apply #{Dir.tmpdir()}#{File::SEPARATOR}taskulator.pp")
  puts "Puppet code executed"
end

params = JSON.parse(STDIN.read)
puppet_code = params['puppet_code']
postinstall_cleanup = params['postinstall_cleanup']
module_names = params['module_names']

begin
  puts "names:               #{module_names}"
  puts "puppet_code:         #{puppet_code}"
  puts "postinstall_cleanup: #{postinstall_cleanup}"
  puts "log dir: #{Dir.tmpdir()}"
  module_names.each do |module_name|
    begin
      install_module(module_name)
    rescue
      puts "couldn't install #{module_name}"
    end
  end

  puppet_apply(puppet_code)

  unless postinstall_cleanup == "no"
    puts "Modules uninstalled"
    module_names.each do |module_name|
      begin
        uninstall_module(module_name)
      rescue
        puts "couldn't uninstall #{module_name}"
      end  
    end
  end
end