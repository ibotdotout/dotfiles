# https://github.com/kevinburke/observr
# modified from  https://gist.github.com/Stubbs/862667

# Prereqs:
# * Ruby
# # * gem install observr
# # For OSX
# # * gem install ruby-fsevent

# Usage
# * observr watchr_python.rb
# # * auto run nosetests <file> when saved it

watch ('(.*).py') {|md| code_changed "#{md[0]}"}

def code_changed(file)
    # clear console
    system("clear")
    # check if it not test file chnage to it's test file
    if not file.end_with?("_test.py")
      file[".py"] = "_test.py"
    end
    # print filename
    print("#{file}\n\n")
    # run nosetests with coverage
    system("nosetests --with-coverage -v #{file}")
end
