#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'open3'
require 'tmpdir'
require "open-uri"

def download(url, path)
  File.open(path, "w") do |f|
    IO.copy_stream(open(url), f)
  end
end

def exec(command)
  output, exit_code  = Open3.popen2({}, command, {:err => [:child, :out]}) do  |i, o, w|
    out = o.read()
    exit_code = w.value.exitstatus
    [out, exit_code]
  end
  
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
puppet_code_url = params['puppet_code_url']

begin
  puts "names:               #{module_names}"
  puts "postinstall_cleanup: #{postinstall_cleanup}"
  puts "log file:            #{Dir.tmpdir()}#{File::SEPARATOR}taskulator.log"
  puts "puppet_code_url:     #{puppet_code_url}"  

  module_names.each do |module_name|
    begin
      install_module(module_name)
    rescue
      puts "couldn't install #{module_name}"
    end
  end

  if !puppet_code_url.empty?
    download(puppet_code_url, "#{Dir.tmpdir()}#{File::SEPARATOR}temp.pp")
    f = File.open("#{Dir.tmpdir()}#{File::SEPARATOR}temp.pp", "rb")
    puppet_code = f.read
  end

  puts "puppet_code:         #{puppet_code}"
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