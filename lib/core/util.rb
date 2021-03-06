require 'fileutils'
require 'paint'
require 'json'
require 'http'
require 'digest'
require 'io/console'
require 'whirly'
require 'os'
require 'json'
require_relative 'constants'

module Rise
  #
  # Utility methods
  #
  module Util
    #
    # Checks if rise is being run for the first time
    #
    def self.first_run?
      !File.directory?(File.join(Dir.home, '.rise'))
    end

    #
    # 1 = git, 2 = gem, 3 = unknown
    #
    def self.git_or_gem
      gem = nil
      1 if File.exist?(File.join(Rise::Constants::VERSION, '.git'))
      if OS.windows?
        gem = system('which gem > NUL')
      else
        gem = system('which gem > /dev/null')
      end

      2 if gem == true
      3
    end

    #
    # Check for a new version of the gem
    #
    def self.check_for_update!
      src = Rise::Util.git_or_gem
      begin
        if src == 2  # if the gem was downloaded from rubygems
          current_version = JSON.parse(HTTP.get('https://rubygems.org/api/v1/versions/rise-cli/latest.json'))['version']
          if current_version != Rise::Constants::VERSION
            Whirly.start(
              spinner: 'line',
              status: "New version available (#{Paint[Rise::Constants::VERSION, 'red']} -> #{Paint[current_version, '#3498db']}), updating..."
            ) do
              system("gem uninstall rise-cli -v #{Rise::Constants::VERSION} > /dev/null")
              system("gem install rise-cli > /dev/null")
              puts Paint["Update complete, just run #{Paint['`rise`', '#3498db']} to deploy"]
            end
          end
        elsif src == 1
          if `git log HEAD..origin/master --oneline` != ''
            puts "It seems you're on bleeding edge, fetching new changes..."
            vputs("Updating from #{`git show --no-color --oneline -s`.split(' ')[0]} to #{`git rev-parse --short HEAD`}")
            `git pull`
            puts Paint["Update complete, just run #{Paint['`rise`', '#3498db']} to deploy"]
          end
        end
      rescue StandardError => e
        puts "Unable to check for updates. Error: #{Paint[e.message, 'red']}"
        exit 1
      end
    end

    #
    # Creates all of the necessary files and login information
    #
    def self.setup
      puts Paint['Detected first time run, creating necessary files...', :blue]
      FileUtils.mkdir(RISE_DATA_DIR)
      FileUtils.mkdir(File.join(RISE_DATA_DIR, 'auth'))

      # TODO: Reimplement when the backend server actually works
      #  Get the input from the user
      # print Paint['1. Log in\n2. Sign up\n  > ', :bold]
      # while (choice = gets.chomp!)
      #   if choice == '1'
      #     login
      #     break
      #   elsif choice == '2'
      #     signup
      #     break
      #   else
      #     puts Paint['Please type `1` or `2`', :red]
      #     next
      #   end
      # end
    end

    #
    # Opens +url+ in a web browser if possible
    #
    def self.open_deployment_in_browser(url)
      if OS.windows?
        system("START \"\" \"#{url}\"")
      else
        system("open #{url}")
      end
    end

  end
end
