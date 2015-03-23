# McFS
Multi-cloud File System

## Usage for devs

Install Ubuntu 14.10 and run the following commands to install necessary tools:

	$ sudo apt-get install ruby ruby-dev libfuse-dev git
	$ sudo gem install rake

Next clone the mcfs repository and change to the checkout out mcfs directory. Run the following command to build the mcfs gem:

	$ rake build

The above command would generate the mcfs gem file. Note the generated mcfs gem filename and run the following command:

	$ sudo gem install ./<gemfile>


Follow instructions given https://www.dropbox.com/developers/core/start/ruby to register two distinct Dropbox apps in your Dropbox app console. Follow further instructions given in the page to generate two separate authentication tokens to connect to the 2 separate dropbox accounts. Generate the following config file that contains the auth tokens required to access two dropbox accounts.

$HOME/.mcfs/config.yml:

```yaml
---
accounts:
- token: token1
- token: token2
```

On Ubuntu machine, now mcfs command to mount the online accounts to an empty directory:

	$ mcfs <dir>

Wait for the client to download metadata of Dropbox contents.
