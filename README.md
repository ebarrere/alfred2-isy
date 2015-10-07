# Alfred 2 ISY control

Control ISY99i device from Alfred

## Features

* Automatic scan of ISY for devices & scenes
* Caching of device/scene list for improved performance
* Turn on and off devices/scenes by "actioning"
  * Actioning without an argument toggles the current state
  * Actioning with "on" or "off" does the appropriate action
  * Set "on level" of device with, e.g. "isy Kitchen:50" for 50%
* Tab-completion of a device completes with : for easy parameter entry

## Setup

Clone the project somewhere

```git clone https://github.com/ebarrere/alfred2-isy /path/to/folder```

Link project to Alfred Workflow folder

```
cd ~/Library/Application Support/Alfred 2/Alfred.alfredpreferences/workflows
ln -s /path/to/folder/workflow <name>
```

Get dependencies

```
cd /path/to/folder
bundle install
```

Add isy_config.rb

```
echo "$isy_config = {:hostname => 'https://isy.domain.com', :username => 'my_username', :password => 'my_password' }" > /path/to/folder/workflow/isy_config.rb
```
