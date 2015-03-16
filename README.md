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


Follow instructions given https://www.dropbox.com/developers/core/start/ruby to register two distinct Dropbox apps in your Dropbox app console. Follow further instructions given in the page to generate two separate authentication tokens to connect to the 2 separate dropbox accounts. Generate the following two files that contains the auth tokens required to access two dropbox accounts.

$HOME/.mcfs/dropbox1.yml:

```yaml
--- !ruby/object:DropboxConfig
app_key: aaaaa
app_secret: aaaaa
access_token: token1
user_id: aaaaa
```

$HOME/.mcfs/dropbox2.yml:
```yaml
--- !ruby/object:DropboxConfig
app_key: aaaaa
app_secret: aaaaa
access_token: token2
user_id: aaaaa
```

Create an empty top-level directory named 'McFS' under both the dropbox accounts.

On Ubuntu machine, now mcfs command to mount the online accounts to an empty directory:

	$ mcfs <dir>

