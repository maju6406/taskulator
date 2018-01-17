#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'open3'
require 'tmpdir'

def exec(command)
  output, exit_code  = Open3.popen2({}, command, {:err => [:child, :out]}) do  |i, o, w|
    out = o.read()
    exit_code = w.value.exitstatus
    [out, exit_code]
  end

  puts "output:#{output}"
  puts "exit  :#{exit_code}"

  { _output: output,
    exit_code: exit_code
  }
end

def install_module(mod)
  exec("puppet module install #{mod} >>#{Dir.tmpdir()}#{File::SEPARATOR}taskulator_install.log")
  puts "#{mod} installed"
end

def uninstall_module(mod)
  exec("puppet module uninstall #{mod} >>#{Dir.tmpdir() }#{File::SEPARATOR}taskulator_uninstall.log")
end

def puppet_apply(code)
  File.open("#{Dir.tmpdir()}#{File::SEPARATOR}taskulator.pp", 'w') { |file| file.write("#{code}") }  
  exec("puppet apply #{Dir.tmpdir()}#{File::SEPARATOR}taskulator.pp >#{Dir.tmpdir()}#{File::SEPARATOR}taskulator.log")
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