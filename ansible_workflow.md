it j
# Ansible Workflow

## Overview

Ansible should be developed in a tested & modular process such that infrastructure is built by composing a number of independent modules (called **roles** in Ansible).  This allows for flexibility of developing each component module independently from the rest.  This workflow aims to facilitate this development process.

Ideally Ansible roles should follow the standards set by the Ansible community for publishing roles in the [Ansible Galaxy](https://galaxy.ansible.com/).  This forces roles to follow consistent patterns that are easy for other developers to follow.

This guide assumes the development workstation is an Apple OS X system.  If using Linux or Windows, some of the guidelines will have to be altered appropriately.

## Prerequisite Tools/Packages

### Install Ansible

The easiest way to get stable Ansible is to use [Homebrew](http://brew.sh/).   Install Homebrew, then simply install Ansible with the following:

    $ brew install ansible

When finished the following command should work as follows (version number may differ):

    $ ansible --version
    ansible 2.0.0.2
      config file = /Users/$USER/.ansible.cfg
      configured module search path = Default w/o overrides

### Install Vagrant

Vagrant is an integral part of the test-driven development workflow as it provides a tool for starting, managing & controlling virtual machines.  `test-kitchen` (described below) wraps Vagrant under the covers.  Vagrant can be downloaded from the [Vagrant download page](https://www.vagrantup.com/).

In addition to Vagrant, VirtualBox will also be necessary (unless using a different virtualization platform - see the Vagrant docs for information on running with something other than VirtualBox) which can be downloaded from [VirtualBox's download page](https://www.virtualbox.org/wiki/Downloads).

Alternatively, both can be installed via Homebrew with the following commands:

    $ brew cask install virtualbox vagrant

## Initializing an Ansible Role

To create a new Ansible role use the `ansible-galaxy` command to generate the scaffolding including all the necessary directories, base (empty) files and metadata necessary:

    $ ansible-galaxy init <role_name>

The above command will generate a new sub-directory in the directory you're currently in with the name of the role you passed.  Within this directory will be a number of directories & files that compose a standard Ansible role:

    helloworld
    ├── README.md
    ├── defaults
    │   └── main.yml
    ├── files
    ├── handlers
    │   └── main.yml
    ├── meta
    │   └── main.yml
    ├── tasks
    │   └── main.yml
    ├── templates
    ├── tests
    │   ├── inventory
    │   └── test.yml
    └── vars
        └── main.yml

## Initializing kitchen-ansible

In order to do test-driven-development it's good to have a proper frame-work to run the Ansible code in virtual development machines before deploying to production.  A great tool for this is [kitchen-ansible](https://github.com/neillturner/kitchen-ansible) which is a derivative of [test-kitchen](https://github.com/test-kitchen/test-kitchen) designed specifically for Ansible.  

Once the role scaffolding is generated as above it is necessary to initialize the role for test-kitchen.  This can be done in one of two ways depending on which virtualization system you chose to work with.  

### Using Vagrant

The benefits of using Vagrant as the provider is that full virtual machines are used as the base for provisioning.  This means an entire guest operating system and all the appropriate tools are included in a self-contained virtual machine.  In some cases this is necessary over using Docker (see below) as some lower-level systems require low-level administrative privileges to work properly.  These can either be dangerous to allow in Docker or, in some cases, impossible.  

Initialize a Vagrant-based test-kitchen project with the following command:

    $ kitchen init --driver=vagrant --provisioner=ansible --create-gemfile

### Using Docker

Docker has the benefit of being far lighter-weight than using Vagrant.  Docker doesn't build an entire virtual machine but instead creates a container with just the parts of the system that are different from the host operating system needed to run the code within the container.  While this is a huge improvement on development velocity it does have some draw-backs.  Docker is based on features in the Linux kernel & thus isn't natively available in OS X.  In order to use Docker a special virtual machine is started running Linux & Docker functions are run within that virtual machine.  Once the Docker VM is running the speed advantages of Docker are still available, but there is an extra layer to deal with.  There are tools from Docker that make running Docker on OS X much easier, hoewever.  Follow the instructions on [Docker's OS X setup page](https://docs.docker.com/mac/) to get your workstation setup properly.

Another draw-back with Docker development is that some functionality is restricted in containers at very low levels.  For example, `systemd` is becoming more and more popular in modern Linux distributions but it requires certain low-level privileges in the kernel that are normally restricted within Docker as they pose a security risk with other containers running on the same host.  While there are ways of getting around this particular issue, it requires forcing unsafe Docker usage and isn't entirely reliable.  

To initialize a Docker-based test-kitchen project with the following command:

    $ kitchen init --driver=docker --provisioner=ansible --create-gemfile

Note that when using Docker it is very important to have a recent version of Ruby installed (>2.2.2) or else kitchen-docker will have problems working.  

### Setup the Gemfile

kitchen-ansible requires a few additional tools to be installed in order to work properly.  The best way to handle this is via an included `Gemfile` in the role project.  This makes it possible to bundle the requirements with the role itself.  The `kitchen init` command mentioned above actually creates a sparsely populated `Gemfile` that is a good foundation to start from.  Simply edit this file and add a couple additional lines so it looks like the following:

    source "https://rubygems.org"

    gem "test-kitchen"
    gem "kitchen-vagrant"
    gem "kitchen-ansible"
    gem "vagrant"
    gem "serverspec"

If the role is using Docker, the above `Gemfile` should include `kitchen-docker` instead of `kitchen-vagrant`.  Run `bundle install` inside the role project directory to install all the necessary Gems and their dependencies.

## Configuring kitchen-ansible

Once the Ansible role has been initialized with kitchen-ansible a new file called `.kitchen.yml` will have been created in the project directory.  This file configures how kitchen-ansible will manage the underlying virtualization platform (driver) and run the provisioner.  One of the powerful features of test-kitchen is that it can be configured to automatically manage multiple instances & multiple operating system platforms in a single configuration file.  This means it's possible to test an Ansible role on CentOS 6, CentOS 7 & Ubuntu 14.04 all with one command.  

The following is an example of a simple kitchen-ansible configuration that will provision the current role on both CentOS 6 & CentOS 7.  Then kitchen-ansible will run through whatever tests are defined on both instances:

### Using Vagrant

    ---
    driver:
      name: vagrant

    provisioner:
      name: ansible
      hosts: localhost
      require_chef_for_busser: false
      require_ruby_for_busser: false

    platforms:
      - name: centos-6.7
      - name: centos-7.1

    suites:
      - name: default
      provisioner:
        name: ansible_playbook
        playbook: test/integration/default/test.yml
        additional_copy_path:
          - "."

### Using Docker:

    ---
    driver:
      name: docker
      provision_command:
      - yum update -y
      - sed -i '/Default.+requiretty/d' /etc/sudoers
      - sed -i '/tsflags=nodocks/d' /etc/yum.conf
      - yum install -y curl

    provisioner:
      name: ansible
      hosts: localhost
      require_chef_for_busser: false
      require_ruby_for_busser: false

    platforms:
      - name: centos-6.7
      - name: centos-7.1

    suites:
      - name: default
      provisioner:
        name: ansible_playbook
        playbook: test/integration/default/test.yml
        additional_copy_path:
          - "."

For this to work a very minimal playbook needs to be created that will be run by the suite as defined in `playbook: test/integration/default/test.yml`.  The contents of this file are simply this:

    ---
    - hosts: localhost
      roles:
        - helloworld

## Configuring Tests

There are a number of ways to configure tests for Ansible role development.  One of the easiest ways is through the use of [ServerSpec](http://serverspec.org/) which provides a framework for defining assertions that are checked against a fully provisioned instance.  kitchen-ansible will boot the instance, provision it with the role as defined & then upload/run all the ServerSpec tests that are defined for each suite.

Each suite in the `.kitchen.yml` will have its own directory in the `test/integration/` directory within the role project.  Within that subdirectory there needs to be another directory to contain the ServerSpec tests that will automatically get loaded into the instance and run by kitchen-ansible.  kitchen-ansible determines what kind of tests are being run by the directory naming so since this example is using ServerSpec the directory will be `test/integration/default/serverspec/`.  Within this directory create one or more files named `*_spec.rb` that contain the assertions to be run on the instance.  An example ServerSpec file looks like this:

    require 'serverspec'

    set :backend, :exec

    describe file('/tmp/hello.txt') do

      it { should exist }
      it { should be_file }
      its(:content) { should match(/Hello world!/) }

    end

The `require` and `set` lines are required in each of the `*_spec.rb` files in order to include the appropriate libraries & set things up properly.  

## Running Tests

The idea behind test-driven-development is that tests are written **before** the logic is written to satisfy the tests.  Therefore it is important that the above ServerSpec file be created before writing any Ansible code and an initial test run completed to actually see it fail.  kitchen is designed to be run as a single command that boots the instance, provisions it, runs tests against it then finally destroys it all in one go, however for development purposes this is probably not the desired process since there is a lot of overhead in booting up and provisioning the instance(s) each time.  A better approach during development is to boot the instance, provision it, run tests then leave it running.  Subsequent code changes can be applied & tested without destroying/rebuilding the instance each time.  

### Initial Start

To bring up the instance, provision & run tests initially run the following command paying close attention to include the `--destroy=never` at the end - this keeps kitchen-ansible from shutting down & destroying the instance at the end even if the tests all pass (by default the instance stays running if any tests fail so it can be entered for troubleshooting):

    $ kitchen test --destroy=never

Note that if there are multiple platforms and/or suites defined in the `.kitchen.yml` file the above command will boot, provision & test multiple VMs to satisfy all the combinations of platform & suite.  It's possible to see all the VMs that kitchen-ansible will manage with the following command:

    $ kitchen list
    Instance           Driver   Provisioner      Verifier  Transport  Last Action
    default-centos-67  Vagrant  AnsiblePlaybook  Busser    Ssh        Set Up
    default-centos-71  Vagrant  AnsiblePlaybook  Busser    Ssh        Verified

If it's desired to just develop against a single instance, then the instance name can be supplied to kitchen as follows:

    $ kitchen test default-centos-71 --destroy=never

### Development Cycle

Once the instance(s) are initially brought up work can be done to develop the logic to satisfy the tests that have been written.  For this example the `/tmp/hello.txt` file should be populated so a task will be added to `tasks/main.yml` as follows:

    ---
    - name: Create hello.txt file
      copy: dest=/tmp/hello.txt content="Hello world!"

After the task is complete it can be applied & tested with kitchen as follows:

    $ kitchen converge && kitchen verify

The above two commands will re-provision the instance(s) with the newly changed Ansible code followed by uploading & running all the ServerSpec tests again.  This process is repeated while various aspects of the role are developed.  The best practice is to work on tiny chunks of functionality at a time.  Each chunk starts with a test followed by the logic to satisfy the test followed by a commit.

# Troubleshooting

When trying to run `brew cask install virtualbox vagrant` the following error appears:

    Error: Permission denied - /Library/Ruby/Gems/2.0.0/specifications/addressable-2.3.8.gemspec


This is due to a permissions error on the `/Library/Ruby/Gems/2.0.0` directory. Fortunately this can be rectified by removing and reinstalling this directory and the gems within:


    sudo rm -rf /Library/Ruby/Gems/2.0.0
    gem update --system

---
