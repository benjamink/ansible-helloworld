require 'serverspec'

set :backend, :exec

describe file('/tmp/hello.txt') do

  it { should exist }
  it { should be_file }
  its(:content) { should match(/Hello world!/) }

end
