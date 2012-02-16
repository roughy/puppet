begin test_name "puppet module list (with missing dependencies)"

step "Setup"
apply_manifest_on master, <<-PP
file {
  [
    '/etc/puppet/modules',
    '/etc/puppet/modules/appleseed',
    '/etc/puppet/modules/crakorn',
    '/etc/puppet/modules/thelock',
    '/usr/share/puppet',
    '/usr/share/puppet/modules',
    '/usr/share/puppet/modules/crick',
  ]: ensure => directory,
     recurse => true,
     purge => true,
     force => true;
  '/etc/puppet/modules/appleseed/metadata.json':
    content => '{
      "name": "jimmy/appleseed",
      "version": "1.1.0",
      "source": "",
      "author": "jimmy",
      "license": "MIT",
      "dependencies": [
        { "name": "jimmy/crackorn", "version_requirement": "0.4.0" }
      ]
    }';
  '/etc/puppet/modules/thelock/metadata.json':
    content => '{
      "name": "jimmy/thelock",
      "version": "1.0.0",
      "source": "",
      "author": "jimmy",
      "license": "MIT",
      "dependencies": [
        { "name": "jimmy/appleseed", "version_requirement": "1.x" },
        { "name": "jimmy/sprinkles", "version_requirement": "2.x" }
      ]
    }';
  '/usr/share/puppet/modules/crick/metadata.json':
    content => '{
      "name": "jimmy/crick",
      "version": "1.0.1",
      "source": "",
      "author": "jimmy",
      "license": "MIT",
      "dependencies": [
        { "name": "jimmy/crackorn", "version_requirement": "v0.4.x" }
      ]
    }';
}
PP
on master, '[ -d /etc/puppet/modules/appleseed ]'
on master, '[ -d /etc/puppet/modules/thelock ]'
on master, '[ -d /usr/share/puppet/modules/crick ]'

step "List the installed modules"
on master, puppet('module list') do
  assert_equal <<-STDERR, stderr
Warning: Missing dependency 'jimmy-crakorn':
  'jimmy-appleseed' (v1.1.0) requires 'jimmy-crakorn' (v0.4.0)
  'jimmy-crick' (v1.0.1) requires 'jimmy-crakorn' (v0.4.x)
Warning: Missing dependency 'jimmy-crakorn':
  'jimmy-appleseed' (v1.1.0) requires 'jimmy-crakorn' (v2.x)
STDERR
  assert_equal <<-STDOUT, stdout
/etc/puppet/modules
├── jimmy-appleseed (v1.1.0)
└── jimmy-thelock (v1.0.0)
/usr/share/puppet/modules
└── jimmy-crick (v1.0.1)
STDOUT
end

step "List the installed modules as a dependency tree"
on master, puppet('module list') do
  assert_equal <<-STDERR, stderr
Warning: Missing dependency 'jimmy-crakorn':
  'jimmy-appleseed' (v1.1.0) requires 'jimmy-crakorn' (v0.4.0)
  'jimmy-crick' (v1.0.1) requires 'jimmy-crakorn' (v0.4.x)
Warning: Missing dependency 'jimmy-crakorn':
  'jimmy-appleseed' (v1.1.0) requires 'jimmy-crakorn' (v2.x)
STDERR
  assert_equal <<-STDOUT, stdout
/etc/puppet/modules
└─┬ jimmy-thelock (v1.0.0)
| └─┬ jimmy-appleseed (v1.1.0)
|   └── UNMET DEPENDENCY jimmy-crakorn (v0.4.0)
└── UNMET DEPENDENCY jimmy-sprinkles (v2.x)
/usr/share/puppet/modules
└─┬ jimmy-crick (v1.0.1)
  └── UNMET DEPENDENCY jimmy-crakorn (v0.4.x)
STDOUT
end

ensure step "Teardown"
apply_manifest_on master, "file { ['/etc/puppet/modules', '/usr/share/puppet/modules']: recurse => true, purge => true, force => true }"
end