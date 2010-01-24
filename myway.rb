module MyWay

  current_path = `pwd`.chomp
  user = `echo $USER`.chomp
  INSTALL_PATH = "/Users/#{user}/sites"

  class App
  
    # Remove when testing is finished.
    attr_reader :name, :domain
  
    def initialize(name, domain)
      @name = name
      @domain = domain
      check_variables
      make_application_dir
    end
  
    def check_variables
      self.instance_variables.each do |variable|
        if self.instance_variable_get(variable) == nil
          puts "You must enter a #{variable.to_s.sub(/@/, '')} for the application. Please enter it now."
          self.instance_variable_set(variable, gets.chomp)
        end  
      end
    end    
  
    def make_application_dir
      Dir.chdir INSTALL_PATH
      begin
        Dir.mkdir self.name
      rescue Errno::EEXIST
        puts "**ERROR!!** The application could not be created because the directory #{INSTALL_PATH}/#{self.name} already exists."
        puts "Would you like to rename your application and try again? yes/no?"
        answer = gets.chomp
        if answer == 'yes' || answer == 'y'
          puts "Type a new name for the app."
          self.name = gets.chomp
          retry
        else
          exit
        end
      rescue Exception => e
        puts "**ERROR!!** There was a problem creating the folder for #{self.name}\n The following error occurred: #{e}"
      end
    end
  
  end




  puts "The app name is set to #{app.name}"
  puts "The app domain is set to #{app.domain}"
  puts current_path
  puts current_path.inspect
  puts user.inspect

end