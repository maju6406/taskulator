#!/usr/bin/ruby

require 'json'
require 'open3'
require 'tmpdir'
require 'open-uri'

def download(url, path)
  File.open(path, 'w') do |f|
    IO.copy_stream(open(url), f)
  end
end

def exec(command)
  output, exit_code = Open3.popen2({}, command, err: [:child, :out]) do |_i, o, w|
    out = o.read
    exit_code = w.value.exitstatus
    [out, exit_code]
  end

  File.open("#{Dir.tmpdir}#{File::SEPARATOR}taskulator.log", 'a') { |file| file.write(output.to_s) }

  { _output: output,
    exit_code: exit_code }
end

def install_module(mod)
  exec("/opt/puppetlabs/bin/puppet module install #{mod}")
  puts "#{mod} installed"
end

def uninstall_module(mod)
  exec("/opt/puppetlabs/bin/puppet module uninstall #{mod}")
end

def install_masterless_puppet_linux
  os = linux_variant
  agent_version = '5.3.2'
  if File.exist?('/opt/puppetlabs/puppet/bin/puppet')
    puts 'Puppet already exists on machine. Skipping install'
  else
    if os[:family] == 'RedHat'
      os_version = os[:major_version]
      cmd = <<-CMD
              rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-#{os_version}.noarch.rpm && \
              yum upgrade -y && \
              yum update -y && \
              yum install -y puppet-agent-#{agent_version} && \
              mkdir -p /etc/puppetlabs/facter/facts.d/ && \
              yum clean all
            CMD
    elsif os[:family] == 'Debian'
      os_codename = os[:codename]
      cmd = <<-CMD
              apt-get update && \
              apt-get install --no-install-recommends -y lsb-release wget ca-certificates && \
              wget https://apt.puppetlabs.com/puppet5-release-#{os_codename}.deb && \
              dpkg -i puppet5-release-#{os_codename}.deb  && \
              rm puppet5-release-#{os_codename}.deb  && \
              apt-get update && \
              apt-get install --no-install-recommends -y puppet-agent="#{agent_version}"-1"#{os_codename}" && \
              apt-get remove --purge -y wget && \
              apt-get autoremove -y && \
              apt-get clean && \
              mkdir -p /etc/puppetlabs/facter/facts.d/ && \
              rm -rf /var/lib/apt/lists/*
            CMD
    end

    if cmd.nil?
      puts 'Could not install puppet. Exiting'
      exit 2
    end

    exec(cmd)
  end
end

def uninstall_masterless_puppet_linux
  os = linux_variant
  agent_version = '5.3.2'
  if os[:family] == 'RedHat'
    os_version = os[:major_version]
    cmd = "rpm -e puppet-agent-#{agent_version}-1.el#{os_version}.x86_64"
  else
    cmd = 'dpkg --remove puppet-agent'
  end
  exec(cmd)
end

def install_masterless_puppet_windows
  agent_version = '5.3.2'
  ps = <<-PS
        $MsiUrl = "https://downloads.puppetlabs.com/windows/puppet/puppet-agent-#{agent_version}-x64.msi"
        Write-Host "Puppet version $PuppetVersion specified, updated MsiUrl to `"$MsiUrl`""
        $PuppetInstalled = $false
        try {
          $ErrorActionPreference = "Stop";
          Get-Command puppet | Out-Null
          $PuppetInstalled = $true
          $PuppetVersion=&puppet "--version"
          Write-Host "Puppet $PuppetVersion is installed. This process does not ensure the exact version or at least version specified, but only that puppet is installed. Exiting..."
          Exit 0
        } catch {
          Write-Host "Puppet is not installed, continuing..."
        }
        if (!($PuppetInstalled)) {
          $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
          if (! ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
            Write-Host -ForegroundColor Red "You must run this script as an administrator."
            Exit 1
          }
          $install_args = @("/qn", "/norestart","/i", $MsiUrl)
          Write-Host "Installing Puppet. Running msiexec.exe $install_args"
          $process = Start-Process -FilePath msiexec.exe -ArgumentList $install_args -Wait -PassThru
          if ($process.ExitCode -ne 0) {
            Write-Host "Installer failed."
            Exit 1
          }
          Write-Host "Stopping Puppet service that is running by default..."
          Start-Sleep -s 5
          Stop-Service -Name puppet
          Write-Host "Puppet successfully installed."
        }
      PS
  File.open("#{Dir.tmpdir}#{File::SEPARATOR}install_agent.ps1", 'w') { |file| file.write(ps) }
  exec("powershell.exe #{Dir.tmpdir}#{File::SEPARATOR}install_agent.ps1")
end

def uninstall_masterless_puppet_windows
  exec('MsiExec.exe /X{68FA13E5-9935-48F5-96F4-20FCAC8FE304}')
end

def puppet_apply(code)
  File.open("#{Dir.tmpdir}#{File::SEPARATOR}taskulator.pp", 'w') { |file| file.write(code.to_s) }
  exec("/opt/puppetlabs/bin/puppet apply #{Dir.tmpdir}#{File::SEPARATOR}taskulator.pp")
  puts 'Puppet code executed'
end

def linux_variant
  r = { distro: nil, family: nil }

  if File.exist?('/etc/lsb-release')
    File.open('/etc/lsb-release', 'r').read.each_line do |line|
      r = { distro: $1 } if line =~ %r{/^DISTRIB_ID=(.*)/}
      r[:codename] = `cat /etc/lsb-release |  grep DISTRIB_CODENAME | cut -d= -f2`.chomp!
      r[:version] = `cat /etc/lsb-release |  grep DISTRIB_RELEASE | cut -d= -f2`.chomp!
    end
  end

  if File.exist?('/etc/debian_version')
    r[:distro] = 'Debian' if r[:distro].nil?
    r[:family] = 'Debian' if r[:variant].nil?
  elsif File.exist?('/etc/redhat-release') || File.exist?('/etc/centos-release')
    r[:family] = 'RedHat' if r[:family].nil?
    r[:distro] = 'CentOS' if File.exist?('/etc/centos-release')
    version = `cat /etc/redhat-release`
    if version.include? "release 7"
      r[:major_version] = '7'
    elsif version.include? "release 7"
      r[:major_version] = '6'
    end
  end
  puts r
  r
end

params = JSON.parse(STDIN.read)
puppet_code = params['puppet_code']
postinstall_cleanup = params['postinstall_cleanup']
module_names = params['module_names']
puppet_code_url = params['puppet_code_url']
install_masterless_puppet = params['install_masterless_puppet']

begin
  puts "names:               #{module_names}"
  puts "postinstall_cleanup: #{postinstall_cleanup}"
  puts "log file:            #{Dir.tmpdir}#{File::SEPARATOR}taskulator.log"
  puts "puppet_code_url:     #{puppet_code_url}"
  puts "install_puppet:      #{install_masterless_puppet}"

  if puppet_code_url.to_s.empty? && puppet_code.to_s.empty?
    puts 'You must specify either puppet_code_url OR puppet_code parameter for this task to function. Try again.'
    exit 1
  end

  if install_masterless_puppet == 'yes'
    if Gem.win_platform?
      install_masterless_puppet_windows
    else
      install_masterless_puppet_linux
    end
  end

  module_names.each do |module_name|
    begin
      install_module(module_name)
    rescue StandardError => e
      puts "couldn't install #{module_name} #{e.message}"
    end
  end

  unless puppet_code_url.to_s.empty?
    download(puppet_code_url, "#{Dir.tmpdir}#{File::SEPARATOR}temp.pp")
    f = File.open("#{Dir.tmpdir}#{File::SEPARATOR}temp.pp", 'rb')
    puppet_code = f.read
  end

  puts "puppet_code:         #{puppet_code}"
  puppet_apply(puppet_code)

  unless postinstall_cleanup == 'no'
    puts 'Modules uninstalled'
    module_names.each do |module_name|
      begin
        uninstall_module(module_name)
      rescue StandardError => e
        puts "couldn't uninstall #{module_name}  #{e.message}"
      end
    end

    if Gem.win_platform?
      uninstall_masterless_puppet_windows
    else
      uninstall_masterless_puppet_linux
    end
  end
end
