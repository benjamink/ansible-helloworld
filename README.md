helloworld
==========

Demonstration Ansible role to be used as an educational template when learning how to develop in Ansible.

Requirements
------------

Running `bundle install` will install the appropriate Ruby Gems necessary for using `kitchen-ansible` & ServerSpec tests.  See the included `ansible_workflow.md` document for detailed instructions on how to develop Ansible roles.

Role Variables
--------------

  * `helloworld_text` - String content to be written to `/tmp/hello.txt` by the role

Dependencies
------------

This role does not depend on any other Ansible roles.

Example Playbook
----------------

    - hosts: localhost
      roles:
         - helloworld

License
-------

BSD

Author Information
------------------

Wildbit, LLC <sys-team@wildbit.com>
