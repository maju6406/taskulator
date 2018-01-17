#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'open3'

def exec(command)
  output, exit_code  = Open3.popen2({}, command, {:err => [:child, :out]}) do  |i, o, w|
    out = o.read()
    exit_code = w.value.exitstatus
    [out, exit_code]
  end

  { _output: output,
    exit_code: exit_code
  }
end

def install_module(mod)
  result = exec("puppet module install #{mod} &>>/tmp/taskulator_install.log")
  puts "install module name: #{mod}"
  puts result.to_json
end

def uninstall_module(mod)
  result = exec("puppet module install #{mod} &>>/tmp/taskulator_install.log")
  puts "uninstall module name: #{mod}"
  puts result.to_json
end

def puppet_apply(code)
  File.open("/tmp/taskulator.pp", 'w') { |file| file.write("#{code}") }  
  result = exec("puppet apply /tmp/taskulator.pp &>/tmp/taskulator.log")
  puts "puppet_code: #{code}"
  puts result.to_json
end

params = JSON.parse(STDIN.read)
puppet_code = params['puppet_code']
postinstall_cleanup = params['postinstall_cleanup']

begin
  params['module_names'].each do |module_name|
    begin
      install_module(module_name)
    rescue
      puts "couldn't update file #{module_name}"
    end
  end
  puppet_apply(puppet_code)
  puts "postinstall_cleanup: #{postinstall_cleanup}"
  unless postinstall_cleanup == "no"
    params['module_names'].each do |module_name|
      begin
        uninstall_module(module_name)
      rescue
        puts "couldn't update file #{module_name}"
      end  
    end
  end
end